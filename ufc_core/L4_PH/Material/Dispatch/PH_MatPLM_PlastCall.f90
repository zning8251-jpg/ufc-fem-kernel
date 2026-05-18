!===============================================================================
! MODULE: PH_MatPLM_PlastCall
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Dispatch
! BRIEF:  Plastic material dispatch — unified Calc interface (**mat_id 201–227**).
!   W1: same bridge pattern as **PH_MatELA_ElasCall** — **Defn_Invoke_UMAT** track;
!   slot-level family/id remains on **PH_Mat_Desc** at Populate (**PH_Mat_Core** S1–S4).
!   **TypeToId**: category-local `PH_MAT_PLAST_*` subtype `k` maps to `mat_id = 200 + k`
!   for `k=1..27`, except deprecated kinds **13, 14, 25** → invalid id (registry SSOT TBD).
!===============================================================================

MODULE PH_MatPLM_PlastCall
  !! UniField-Core Plastic Mat Definition Module (UMAT single-track)
  !!   LAYER: L4 (Element Library)
  !!   DOMAIN: Mat/Plastic
  !!   KIND: Defn (unified interface for mat_id 201–227)
  !!
  !! This module provides the main plastic Mat interface:
  !!   - UF_Mat_Plast_Calc: Unified interface for plastic materials
  !!   - Routes via Defn_Invoke_UMAT(mat_id) for all plastic types.
  !!
  !! Design Principles:
  !!   - UMAT single-track: Defn -> TypeToId -> Defn_Invoke_UMAT -> Reg
  !! ===================================================================

  USE IF_Base_Def, ONLY: ZERO
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Lib, ONLY: MatProperties
  USE PH_Mat_Defn_UMAT_Bridge, ONLY: Defn_Invoke_UMAT, Defn_Invoke_UMAT_Arg, PH_Mat_TypeToId, &
      PH_MAT_CAT_PLAST, PH_MAT_ID_INVALID

  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  PUBLIC :: UF_Mat_Plast_Calc
  PUBLIC :: UF_Mat_Plast_Calc_Arg

  ! Mat type constants
  INTEGER(i4), PARAMETER :: PH_MAT_PLAST_J2 = 1
  INTEGER(i4), PARAMETER :: PH_MatPlastChaboche_Algo = 2
  INTEGER(i4), PARAMETER :: PH_MatPlastHill_Algo = 3
  INTEGER(i4), PARAMETER :: PH_MAT_PLAST_DRUCKER_PRAGER = 4
  INTEGER(i4), PARAMETER :: PH_MAT_PLAST_MOHR_COULOMB = 5
  INTEGER(i4), PARAMETER :: PH_MAT_PLAST_GURSON = 6
  INTEGER(i4), PARAMETER :: PH_MatPlastBarlat_Algo = 7
  INTEGER(i4), PARAMETER :: PH_MAT_PLAST_HOSFORD = 8
  INTEGER(i4), PARAMETER :: PH_MAT_PLAST_LUDWIK = 9
  INTEGER(i4), PARAMETER :: PH_MAT_PLAST_SWIFT_VOCE = 10
  INTEGER(i4), PARAMETER :: PH_MAT_PLAST_HOCKETT_SHERBY = 11
  INTEGER(i4), PARAMETER :: PH_MAT_PLAST_MIXED_HARDENING = 12
  ! DEPRECATED: PH_MAT_PLAST_PRAGER (13) - Module removed
  ! DEPRECATED: PH_MAT_PLAST_ZIEGLER (14) - Module removed
  INTEGER(i4), PARAMETER :: PH_MAT_PLAST_YOSHIDA_UEMORI = 15
  INTEGER(i4), PARAMETER :: PH_MatPlastCrystal_Algo = 16
  INTEGER(i4), PARAMETER :: PH_MAT_PLAST_SMA = 17
  INTEGER(i4), PARAMETER :: PH_MAT_PLAST_POROUS = 18
  INTEGER(i4), PARAMETER :: PH_MAT_PLAST_GURSON_POROUS = 19
  INTEGER(i4), PARAMETER :: PH_MAT_PLAST_CONCRETE_DP = 20
  INTEGER(i4), PARAMETER :: PH_MAT_PLAST_JOHNSON_COOK = 21
  INTEGER(i4), PARAMETER :: PH_MAT_PLAST_MOHR_COULOMB_EXT = 22
  INTEGER(i4), PARAMETER :: PH_MAT_PLAST_HILL_MUSCLE = 23
  INTEGER(i4), PARAMETER :: PH_MAT_PLAST_MAGNETIC_SMA = 24
  ! DEPRECATED: PH_MAT_PLAST_ROBINSON (25) - Module removed
  INTEGER(i4), PARAMETER :: PH_MAT_PLAST_PLASTICITY = 26
  INTEGER(i4), PARAMETER :: PH_MAT_PLAST_SHAPE_MEMORY = 27

  ! SIO bundle for UF_Mat_Plast_Calc (INTF-001)
  TYPE, PUBLIC :: UF_Mat_Plast_Calc_Arg
    INTEGER(i4) :: matType = 0_i4                    ! [IN] category-local type id
    TYPE(MatProperties) :: Mat                       ! [IN]
    REAL(wp) :: strain_in(6) = 0.0_wp                ! [IN]
    REAL(wp) :: stress_out(6) = 0.0_wp               ! [OUT]
    REAL(wp) :: tangent_out(6, 6) = 0.0_wp           ! [OUT] valid when want_tangent=.TRUE.
    LOGICAL :: want_tangent = .FALSE.                ! [IN] request tangent_out fill
    TYPE(ErrorStatusType) :: status                  ! [OUT]
  END TYPE UF_Mat_Plast_Calc_Arg

CONTAINS

  SUBROUTINE UF_Mat_Plast_Calc(arg)
    TYPE(UF_Mat_Plast_Calc_Arg), INTENT(INOUT) :: arg
    INTEGER(i4) :: mat_id
    TYPE(Defn_Invoke_UMAT_Arg) :: du

    CALL init_error_status(arg%status)
    arg%stress_out = ZERO
    arg%tangent_out = ZERO

    mat_id = PH_Mat_TypeToId(PH_MAT_CAT_PLAST, arg%matType)
    IF (mat_id == PH_MAT_ID_INVALID) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = 'UF_Mat_Plast_Calc: Unknown or unsupported Mat type'
      RETURN
    END IF

    du%mat_id = mat_id
    ALLOCATE(du%mat, source=arg%Mat)
    du%strain_in = arg%strain_in
    du%want_tangent = arg%want_tangent
    CALL Defn_Invoke_UMAT(du)
    arg%stress_out = du%stress_out
    arg%tangent_out = du%tangent_out
    arg%status = du%status
    IF (ALLOCATED(du%mat)) DEALLOCATE(du%mat)

  END SUBROUTINE UF_Mat_Plast_Calc

END MODULE PH_MatPLM_PlastCall
