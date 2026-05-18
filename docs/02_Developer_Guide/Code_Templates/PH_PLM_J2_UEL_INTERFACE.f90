!===============================================================================
! Framework Structure Only: PH_PLM_J2_UEL (interface skeleton)
! Seven-phase UEL architecture: LOAD → Shape → Jacobian → B-matrix → UMAT call
!                              → STORE → Assembly
!===============================================================================
MODULE PH_PLM_J2_UEL
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE MD_Elem_Types, ONLY: MD_Elem_Base_Desc, MD_Elem_Base_Algo
  USE MD_Sect_Types, ONLY: MD_Sect_Registry
  USE PH_Elem_Types, ONLY: PH_Elem_Base_Ctx, PH_Elem_Base_State
  USE PH_Mat_PLM, ONLY: PH_Mat_PLM_State
  USE RT_Com_Types, ONLY: RT_Com_Base_Ctx, RT_PNEWDT_NO_CHANGE
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: PH_PLM_J2_UEL_API

  INTEGER(i4), PARAMETER :: NSVARS_PER_IP = 14_i4  ! stress(6) + stran(6) + ivar1 + ivar2

CONTAINS

  !-- API Wrapper: validate inputs, delegate to Impl
  SUBROUTINE PH_PLM_J2_UEL_API(sect_registry, MD_Elem_Desc, PH_Elem_Ctx, &
      PH_Elem_State, RT_Com_Ctx, pnewdt, uel_status)
    TYPE(MD_Sect_Registry), INTENT(IN), TARGET :: sect_registry
    TYPE(MD_Elem_Base_Desc), INTENT(IN) :: MD_Elem_Desc
    TYPE(PH_Elem_Base_Ctx), INTENT(INOUT) :: PH_Elem_Ctx
    TYPE(PH_Elem_Base_State), INTENT(INOUT) :: PH_Elem_State
    TYPE(RT_Com_Base_Ctx), INTENT(IN) :: RT_Com_Ctx
    REAL(wp), INTENT(INOUT) :: pnewdt
    TYPE(ErrorStatusType), INTENT(OUT) :: uel_status
    ! ... validate inputs and delegate to PH_PLM_J2_UEL_Impl
  END SUBROUTINE

  !-- Core Implementation: seven-phase algorithm
  SUBROUTINE PH_PLM_J2_UEL_Impl(sect_registry, MD_Elem_Desc, PH_Elem_Ctx, &
      PH_Elem_State, RT_Com_Ctx, pnewdt, uel_status)
    TYPE(MD_Sect_Registry), INTENT(IN), TARGET :: sect_registry
    TYPE(MD_Elem_Base_Desc), INTENT(IN) :: MD_Elem_Desc
    TYPE(PH_Elem_Base_Ctx), INTENT(INOUT) :: PH_Elem_Ctx
    TYPE(PH_Elem_Base_State), INTENT(INOUT) :: PH_Elem_State
    TYPE(RT_Com_Base_Ctx), INTENT(IN) :: RT_Com_Ctx
    REAL(wp), INTENT(INOUT) :: pnewdt
    TYPE(ErrorStatusType), INTENT(OUT) :: uel_status
    !$UFC HOT_PATH

    ! PHASE A: SVARS LOAD (per Gauss point)
    ! ─────────────────────────────────────
    ! DO ip = 1, nip
    !   slot_base = (ip - 1) * NSVARS_PER_IP
    !   PH_Mat_State%stress(1:6) ← svars(slot_base+1  : slot_base+6)
    !   PH_Mat_State%stran(1:6)  ← svars(slot_base+7  : slot_base+12)
    !   PH_Mat_State%ivar1       ← svars(slot_base+13)
    !   PH_Mat_State%ivar2       ← svars(slot_base+14)
    ! END DO
    ! Input: PH_Elem_State%svars(:), nip (from MD_Elem_Desc)
    ! Output: PH_Mat_State (per IP, stack variable)

    ! PHASE B: Shape Functions & Jacobian
    ! ────────────────────────────────────
    ! DO ip = 1, nip
    !   ξ, η, ζ ← Gauss point coordinates
    !   N(ξ, η, ζ) ← shape functions
    !   dN/dξ, dN/dη, dN/dζ ← shape derivatives
    !   J = dN/dξ · [coords] ← Jacobian matrix (3×3)
    !   det_J = det(J)
    !   dN/dX = J⁻¹ · dN/dξ ← physical derivatives
    ! END DO
    ! Input: MD_Elem_Desc%nnode, PH_Elem_Ctx%coords(:,:)
    ! Output: N, dN/dX, det_J (per IP)

    ! PHASE C: B-Matrix & Strain Increment
    ! ─────────────────────────────────────
    ! DO ip = 1, nip
    !   B = ∂N/∂X matrix (nt × ndofel) [nt=6 for 3D solid]
    !   dstran_ip = B · du ← strain increment at IP
    !   PH_Elem_Ctx%mat_ctx%dstran(1:nt) ← dstran_ip
    ! END DO
    ! Input: dN/dX, PH_Elem_Ctx%du (displacement increment)
    ! Output: B-matrix, dstran_ip (per IP)

    ! PHASE D: Section & Material Dispatch
    ! ────────────────────────────────────
    ! sect_id = MD_Elem_Desc%jprops(1)
    ! mat_d => sect_registry%sections(sect_id)%mat_desc [CLASS(MD_Mat_Base_Desc)]
    ! SELECT TYPE (md => mat_d)
    !   TYPE IS (MD_Mat_PLM_Desc)
    !     CALL PH_PLM_J2_UMAT_API(md, PH_Elem_Ctx%mat_ctx, &
    !                              PH_Mat_State, MD_Mat_Algo, PH_Mat_Algo, &
    !                              RT_Com_Ctx, pnewdt_ip)
    ! END SELECT
    ! Input: sect_registry, sect_id
    ! Output: σ_{n+1}, D_tan, pnewdt_ip (from UMAT)

    ! PHASE E: SVARS STORE (mirror LOAD)
    ! ──────────────────────────────────
    ! DO ip = 1, nip
    !   slot_base = (ip - 1) * NSVARS_PER_IP
    !   svars(slot_base+1  : slot_base+6)  ← PH_Mat_State%stress(1:6)
    !   svars(slot_base+7  : slot_base+12) ← PH_Mat_State%stran(1:6)
    !   svars(slot_base+13) ← PH_Mat_State%ivar1
    !   svars(slot_base+14) ← PH_Mat_State%ivar2
    ! END DO
    ! Input: PH_Mat_State (updated from UMAT)
    ! Output: PH_Elem_State%svars(:) (persisted to next increment)

    ! PHASE F: Assembly (K, R)
    ! ────────────────────────
    ! DO ip = 1, nip
    !   rhs(:) += B^T · σ · det_J · w_ip
    !   amatrx(:,:) += B^T · D_tan · B · det_J · w_ip
    !   energy(sse) += 0.5·σ·ε·det_J·w_ip
    ! END DO
    ! Input: B-matrix, σ, D_tan, det_J, w_ip
    ! Output: rhs, amatrx, energy (per element)

    ! PHASE G: Step Ratio Feedback
    ! ────────────────────────────
    ! pnewdt_min = MIN(pnewdt_min, pnewdt_ip) [across all IPs]
    ! Input: pnewdt_ip (from each UMAT call)
    ! Output: pnewdt (global step ratio feedback)

    ! Final Outputs
    ! ─────────────
    ! rhs(1:ndofel, 1) = -fint (internal force vector)
    ! amatrx(1:ndofel, 1:ndofel) = K (stiffness matrix)
    ! svars(1:nsvars) = state variables (persisted)
    ! energy(1:8) = energy components
    ! pnewdt = min step ratio
    ! uel_status = error code

  END SUBROUTINE

END MODULE PH_PLM_J2_UEL
