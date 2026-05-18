!===============================================================================
! MODULE: PH_Mat_Defn_UMAT_Bridge
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Brg — UMAT single-track Defn invoke + category→mat_id map (stub SSOT)
! BRIEF:  Minimal **Defn_Invoke_UMAT** + **PH_Mat_TypeToId** for Dispatch/Defn
!   modules and L3 cold-path smoke tests. Full Reg/UMAT routing remains on
!   **PH_Mat_Reg** / Populate gold path; this bridge is intentionally small.
!   **INTF-001**: public **Defn_Invoke_UMAT** uses a single **Defn_Invoke_UMAT_Arg**
!   bundle (no multi-arg surface). Optional **state_inout** is not in the Arg TYPE
!   until a typed carrier exists; extend Arg + body when callers need it.
!===============================================================================
MODULE PH_Mat_Defn_UMAT_Bridge
  USE IF_Base_Def, ONLY: ZERO, ONE, TWO
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Def, ONLY: MatProps
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_ID_INVALID = 0_i4

  ! Category ids (L4 Dispatch + L3 MD_MatLibPH_Brg aliases share numeric values)
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_CAT_ELASTIC = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_CAT_PLAST = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_CAT_SPCL = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_CAT_HYPERELAS = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_CAT_VISC = 5_i4

  INTEGER(i4), PARAMETER, PUBLIC :: CAT_ELASTIC = PH_MAT_CAT_ELASTIC
  INTEGER(i4), PARAMETER, PUBLIC :: CAT_PLAST = PH_MAT_CAT_PLAST
  INTEGER(i4), PARAMETER, PUBLIC :: CAT_HYPERELAS = PH_MAT_CAT_HYPERELAS
  INTEGER(i4), PARAMETER, PUBLIC :: CAT_VISC = PH_MAT_CAT_VISC

  PUBLIC :: PH_Mat_TypeToId
  PUBLIC :: Defn_Invoke_UMAT
  PUBLIC :: Defn_Invoke_UMAT_Arg

  ! SIO bundle for Defn_Invoke_UMAT (INTF-001)
  TYPE, PUBLIC :: Defn_Invoke_UMAT_Arg
    INTEGER(i4) :: mat_id = 0_i4
    CLASS(MatProps), ALLOCATABLE :: mat              ! [IN] dynamic dispatch (e.g. MatProperties)
    REAL(wp) :: strain_in(6) = 0.0_wp                ! [IN]
    REAL(wp) :: stress_out(6) = 0.0_wp               ! [OUT]
    REAL(wp) :: tangent_out(6, 6) = 0.0_wp           ! [OUT] valid when want_tangent=.TRUE.
    LOGICAL :: want_tangent = .FALSE.                ! [IN]
    TYPE(ErrorStatusType) :: status                  ! [OUT]
  END TYPE Defn_Invoke_UMAT_Arg

CONTAINS

  !> Map (material category, category-local mat_subtype) → global mat_id.
  !> Plastic (PH_MAT_CAT_PLAST): **mat_id = 200 + mat_subtype** for mat_subtype=1..27,
  !> excluding deprecated slots **13, 14, 25** (invalid). Band **201–227** aligns with
  !> `PH_MatPLM_PlastCall` PH_MAT_PLAST_* numbering; stub **Defn_Invoke_UMAT** treats 201:227
  !> like 201 until per-model routing exists.
  PURE INTEGER(i4) FUNCTION PH_Mat_TypeToId(cat_id, mat_subtype) RESULT(res)
    INTEGER(i4), INTENT(IN) :: cat_id, mat_subtype

    res = PH_MAT_ID_INVALID
    IF (cat_id == PH_MAT_CAT_ELASTIC .OR. cat_id == CAT_ELASTIC) THEN
      IF (mat_subtype == 1_i4) res = 101_i4
    ELSE IF (cat_id == PH_MAT_CAT_PLAST .OR. cat_id == CAT_PLAST) THEN
      IF (mat_subtype >= 1_i4 .AND. mat_subtype <= 27_i4) THEN
        IF (mat_subtype /= 13_i4 .AND. mat_subtype /= 14_i4 .AND. mat_subtype /= 25_i4) THEN
          res = 200_i4 + mat_subtype
        END IF
      END IF
    ELSE IF (cat_id == PH_MAT_CAT_HYPERELAS .OR. cat_id == CAT_HYPERELAS) THEN
      IF (mat_subtype == 16_i4) res = 303_i4
    ELSE IF (cat_id == PH_MAT_CAT_VISC .OR. cat_id == CAT_VISC) THEN
      IF (mat_subtype == 1_i4) res = 401_i4
    ELSE IF (cat_id == PH_MAT_CAT_SPCL) THEN
      IF (mat_subtype >= 1_i4 .AND. mat_subtype <= 5_i4) res = 604_i4
    END IF
  END FUNCTION PH_Mat_TypeToId

  SUBROUTINE umat_bridge_build_D_iso6(E, nu, D)
    REAL(wp), INTENT(IN) :: E, nu
    REAL(wp), INTENT(OUT) :: D(6, 6)
    REAL(wp) :: lam, mu, c1, c2
    D = ZERO
    IF (E <= ZERO .OR. nu <= -ONE .OR. nu >= 0.5_wp) RETURN
    lam = E * nu / MAX((ONE + nu) * (ONE - TWO * nu), 1.0E-30_wp)
    mu = E / (TWO * (ONE + nu))
    c1 = lam + TWO * mu
    c2 = lam
    D(1, 1) = c1; D(2, 2) = c1; D(3, 3) = c1
    D(1, 2) = c2; D(1, 3) = c2; D(2, 1) = c2
    D(2, 3) = c2; D(3, 1) = c2; D(3, 2) = c2
    D(4, 4) = mu; D(5, 5) = mu; D(6, 6) = mu
  END SUBROUTINE umat_bridge_build_D_iso6

  SUBROUTINE umat_bridge_iso_stress_tangent(Mat, strain_in, stress_out, want_tangent, tangent_out, st)
    CLASS(MatProps), INTENT(IN) :: Mat
    REAL(wp), INTENT(IN) :: strain_in(6)
    REAL(wp), INTENT(OUT) :: stress_out(6)
    LOGICAL, INTENT(IN) :: want_tangent
    REAL(wp), INTENT(OUT) :: tangent_out(6, 6)
    TYPE(ErrorStatusType), INTENT(INOUT) :: st
    REAL(wp) :: D(6, 6), E, nu
    INTEGER(i4) :: i, j

    stress_out = ZERO
    tangent_out = ZERO
    IF (.NOT. ALLOCATED(Mat%props) .OR. Mat%nprops < 2_i4) THEN
      st%status_code = IF_STATUS_INVALID
      st%message = 'Defn_Invoke_UMAT: need at least 2 props (E, nu)'
      RETURN
    END IF
    E = Mat%props(1)
    nu = Mat%props(2)
    CALL umat_bridge_build_D_iso6(E, nu, D)
    DO i = 1, 6
      DO j = 1, 6
        stress_out(i) = stress_out(i) + D(i, j) * strain_in(j)
      END DO
    END DO
    IF (want_tangent) tangent_out = D
    st%status_code = IF_STATUS_OK
  END SUBROUTINE umat_bridge_iso_stress_tangent

  SUBROUTINE Defn_Invoke_UMAT(du)
    TYPE(Defn_Invoke_UMAT_Arg), INTENT(INOUT) :: du
    LOGICAL :: want_t
    REAL(wp) :: tang_loc(6, 6)

    want_t = du%want_tangent
    CALL init_error_status(du%status)
    du%stress_out = ZERO
    IF (want_t) du%tangent_out = ZERO
    tang_loc = ZERO

    IF (.NOT. ALLOCATED(du%mat)) THEN
      du%status%status_code = IF_STATUS_INVALID
      du%status%message = 'Defn_Invoke_UMAT: mat not allocated in Defn_Invoke_UMAT_Arg'
      RETURN
    END IF

    SELECT CASE (du%mat_id)
    CASE (101_i4, 201_i4:227_i4, 303_i4, 401_i4, 604_i4)
      IF (want_t) THEN
        CALL umat_bridge_iso_stress_tangent(du%mat, du%strain_in, du%stress_out, .TRUE., du%tangent_out, du%status)
      ELSE
        CALL umat_bridge_iso_stress_tangent(du%mat, du%strain_in, du%stress_out, .FALSE., tang_loc, du%status)
      END IF
    CASE DEFAULT
      du%status%status_code = IF_STATUS_INVALID
      du%status%message = 'Defn_Invoke_UMAT: unsupported mat_id (bridge stub)'
    END SELECT

  END SUBROUTINE Defn_Invoke_UMAT

END MODULE PH_Mat_Defn_UMAT_Bridge
