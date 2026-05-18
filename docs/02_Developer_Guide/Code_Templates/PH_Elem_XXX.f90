!===============================================================================
! Template: PH_Elem_XXX.f90                                     [Template v4.1+]
! Layer:  L4_PH - Physics Layer
! Domain: Element / [Family] (e.g., CONTI / SHELL / BEAM / TRUSS / ...)
!
! PURPOSE
!   UFC-native element kernel paired with the *consolidated* material module pattern
!   (see PH_Mat_PLM_J2_MatPoint_Template.f90): same call chain as PH_XXX_UEL.f90,
!   but USE names expect a material module that exports both PH_*_UMAT_API and
!   optional MatPoint / PH_*_UMAT(ctx) adapters in one place.
!
! RELATIONSHIP
!   PH_XXX_UEL.f90     — generic UEL; USE PH_XXX_UMAT (minimal module name PH_XXX_UMAT).
!   PH_Elem_XXX.f90    — same UEL logic; USE PH_Mat_XXX_MatPoint (or your instantiated
!                        module such as PH_Mat_PLM_J2) exporting:
!                          MD_Mat_XXX_Desc, PH_Mat_XXX_State, PH_Mat_XXX_UMAT_API
!   Material reference — PH_Mat_PLM_J2_MatPoint_Template.f90 (J2 von Mises).
!
! UEL -> UMAT (native path; matches PH_XXX_UEL)
!   [0] section_id -> sect_registry -> mat_desc pointer
!   [1] Per IP: B, dstran -> PH_Elem_Ctx%mat_ctx; CALL PH_Mat_XXX_UMAT_API(md, ...)
!   Do NOT call PH_*_UMAT(ctx) here — that entry is for PH_UMAT_Context / ABAQUS-style
!   adapters outside the typed UEL loop.
!
! NAMING
!   Module PH_Elem_XXX; API PH_Elem_XXX_API; XXX = C3D8, S4R, beam type, ...
!   Replace PH_Mat_XXX_MatPoint / MD_Mat_XXX_* / PH_Mat_XXX_* with your material module.
!
! HOW TO USE
!   1. Copy to L4_PH/Element/[Family]/PH_[ElemType].f90
!   2. Replace XXX -> element id; wire USE to your material (e.g. PH_Mat_PLM_J2)
!   3. Implement Elem_XXX_Shape_Functions / Jacobian / B_Matrix (rename inner stubs)
!   4. Ensure jprops(1)=section_id, integ_npts > 0, MD_Mat_Algo%ntens consistent
!
! Contract: L4_PH/contracts/CONTRACT_UEL_UMAT_Element_Material.md
!===============================================================================
MODULE PH_Elem_XXX
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_ERROR
  USE MD_Elem_Types,   ONLY: MD_Elem_Base_Desc
  USE MD_Sect_Types,   ONLY: MD_Sect_Base_Desc, MD_Sect_Registry
  USE MD_Mat_Types,    ONLY: MD_Mat_Base_Desc, MD_Mat_Base_Algo
  USE PH_Elem_Types,   ONLY: PH_Elem_Base_Ctx, PH_Elem_Base_State
  ! Consolidated material module (placeholder): instantiate e.g. USE PH_Mat_PLM_J2, ONLY: ...
  USE PH_Mat_XXX_MatPoint, ONLY: PH_Mat_XXX_State, PH_Mat_XXX_UMAT_API, MD_Mat_XXX_Desc
  USE PH_Mat_Types,    ONLY: PH_Mat_Base_Algo, PH_Mat_Base_Ctx
  USE RT_Com_Types, ONLY: RT_Com_Base_Ctx, RT_PNEWDT_NO_CHANGE
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Elem_XXX_API

CONTAINS

  SUBROUTINE PH_Elem_XXX_API(Sect_Registry, MD_Elem_Desc, PH_Elem_Ctx, PH_Elem_State, &
      RT_Com_Ctx, pnewdt, Elem_status)
    TYPE(MD_Sect_Registry),    INTENT(IN), TARGET :: Sect_Registry
    TYPE(MD_Elem_Base_Desc),   INTENT(IN)    :: MD_Elem_Desc
    TYPE(PH_Elem_Base_Ctx),    INTENT(INOUT) :: PH_Elem_Ctx
    TYPE(PH_Elem_Base_State),  INTENT(INOUT) :: PH_Elem_State
    TYPE(RT_Com_Base_Ctx),     INTENT(IN)    :: RT_Com_Ctx
    REAL(wp),                  INTENT(INOUT) :: pnewdt
    TYPE(ErrorStatusType),     INTENT(OUT)   :: Elem_status

    INTEGER(i4) :: sect_id, sect_idx
    CLASS(MD_Mat_Base_Desc), POINTER :: mat_d => NULL()
    TYPE(PH_Mat_XXX_State)    :: PH_Mat_State
    TYPE(MD_Mat_Base_Algo)    :: MD_Mat_Algo
    TYPE(PH_Mat_Base_Algo)    :: PH_Mat_Algo
    REAL(wp)                  :: pnewdt_ip

    REAL(wp) :: B(6,24), N(8), dNdX(3,8), xi, eta, zeta, w_ip, det_J
    REAL(wp) :: dstran_ip(6), fint(24), pnewdt_min
    INTEGER(i4) :: ip, ndofel, nip, nt

    CALL init_error_status(Elem_status)
    ndofel = MD_Elem_Desc%ndofel
    nip = MD_Elem_Desc%integ_npts
    IF (nip <= 0) THEN
      CALL init_error_status(Elem_status, IF_STATUS_ERROR, &
          message='[Elem_XXX]: MD_Elem_Desc%integ_npts must be set > 0 before element call')
      pnewdt = 0.0_wp
      RETURN
    END IF
    IF (.NOT. ALLOCATED(MD_Elem_Desc%jprops) .OR. SIZE(MD_Elem_Desc%jprops) < 1) THEN
      CALL init_error_status(Elem_status, IF_STATUS_ERROR, &
          message='[Elem_XXX]: jprops(1) required for section_id')
      pnewdt = 0.0_wp
      RETURN
    END IF

    pnewdt_min = RT_PNEWDT_NO_CHANGE
    nt = MD_Mat_Algo%ntens
    IF (nt < 1 .OR. nt > 6) nt = 6

    IF (ALLOCATED(PH_Elem_State%rhs))    PH_Elem_State%rhs    = 0.0_wp
    IF (ALLOCATED(PH_Elem_State%amatrx)) PH_Elem_State%amatrx = 0.0_wp
    PH_Elem_State%energy = 0.0_wp
    fint = 0.0_wp

    sect_id  = MD_Elem_Desc%jprops(1)
    sect_idx = Sect_Registry%GetSectIdx(sect_id)
    IF (sect_idx == 0) THEN
      CALL init_error_status(Elem_status, IF_STATUS_ERROR, &
          message='[Elem_XXX]: section_id not found in registry')
      pnewdt = 0.0_wp
      RETURN
    END IF

    mat_d => Sect_Registry%sections(sect_idx)%mat_desc
    IF (.NOT. ASSOCIATED(mat_d)) THEN
      CALL init_error_status(Elem_status, IF_STATUS_ERROR, &
          message='[Elem_XXX]: section mat_desc not associated')
      pnewdt = 0.0_wp
      RETURN
    END IF

    DO ip = 1, nip
      CALL Elem_XXX_Get_Gauss_Point(ip, nip, xi, eta, zeta, w_ip)
      CALL Elem_XXX_Shape_Functions(xi, eta, zeta, N)
      CALL Elem_XXX_Jacobian(PH_Elem_Ctx%coords, N, xi, eta, zeta, dNdX, det_J)

      IF (det_J <= 0.0_wp) THEN
        CALL init_error_status(Elem_status, IF_STATUS_ERROR, &
            message='[Elem_XXX]: non-positive Jacobian at IP')
        pnewdt = 0.0_wp
        RETURN
      END IF

      CALL Elem_XXX_B_Matrix(dNdX, B)
      dstran_ip(1:nt) = MATMUL(B(1:nt,1:ndofel), PH_Elem_Ctx%du(1,1:ndofel))
      IF (nt < 6) dstran_ip(nt+1:6) = 0.0_wp

      PH_Elem_Ctx%mat_ctx%dstran(1:nt) = dstran_ip(1:nt)
      IF (nt < 6) PH_Elem_Ctx%mat_ctx%dstran(nt+1:6) = 0.0_wp

      pnewdt_ip = RT_PNEWDT_NO_CHANGE
      SELECT TYPE (md => mat_d)
      TYPE IS (MD_Mat_XXX_Desc)
        CALL PH_Mat_XXX_UMAT_API(md, PH_Elem_Ctx%mat_ctx, PH_Mat_State, MD_Mat_Algo, PH_Mat_Algo, &
            RT_Com_Ctx, pnewdt_ip)
      CLASS DEFAULT
        CALL init_error_status(Elem_status, IF_STATUS_ERROR, &
            message='[Elem_XXX]: mat_desc type not MD_Mat_XXX_Desc (extend SELECT for multi-mat)')
        pnewdt = 0.0_wp
        RETURN
      END SELECT

      IF (PH_Mat_State%status%status_code /= IF_STATUS_OK) THEN
        elem_status = PH_Mat_State%status
        pnewdt = 0.0_wp
        RETURN
      END IF

      pnewdt_min = MIN(pnewdt_min, pnewdt_ip)

      fint(1:ndofel) = fint(1:ndofel) &
          + MATMUL(TRANSPOSE(B(1:nt,1:ndofel)), PH_Mat_State%stress(1:nt)) * det_J * w_ip

      IF (ALLOCATED(PH_Elem_State%amatrx)) THEN
        PH_Elem_State%amatrx(1:ndofel,1:ndofel) = PH_Elem_State%amatrx(1:ndofel,1:ndofel) &
            + MATMUL(MATMUL(TRANSPOSE(B(1:nt,1:ndofel)), PH_Mat_State%ddsdde(1:nt,1:nt)), &
                     B(1:nt,1:ndofel)) * det_J * w_ip
      END IF

      PH_Elem_State%energy(1) = PH_Elem_State%energy(1) &
          + PH_Mat_State%elastic_energy * det_J * w_ip
    END DO

    IF (ALLOCATED(PH_Elem_State%rhs)) &
        PH_Elem_State%rhs(1:ndofel,1) = -fint(1:ndofel)

    pnewdt = MIN(pnewdt, pnewdt_min)
    CALL init_error_status(elem_status, IF_STATUS_OK)

  CONTAINS

    SUBROUTINE Elem_XXX_Get_Gauss_Point(ip, npts, xi_out, eta_out, zeta_out, w_out)
      INTEGER(i4), INTENT(IN)  :: ip, npts
      REAL(wp),    INTENT(OUT) :: xi_out, eta_out, zeta_out, w_out
      REAL(wp), PARAMETER :: GP1 = 0.577350269189626_wp
      SELECT CASE (ip)
      CASE (1); xi_out=-GP1; eta_out=-GP1; zeta_out=-GP1; w_out=1.0_wp
      CASE (2); xi_out= GP1; eta_out=-GP1; zeta_out=-GP1; w_out=1.0_wp
      CASE (3); xi_out= GP1; eta_out= GP1; zeta_out=-GP1; w_out=1.0_wp
      CASE (4); xi_out=-GP1; eta_out= GP1; zeta_out=-GP1; w_out=1.0_wp
      CASE (5); xi_out=-GP1; eta_out=-GP1; zeta_out= GP1; w_out=1.0_wp
      CASE (6); xi_out= GP1; eta_out=-GP1; zeta_out= GP1; w_out=1.0_wp
      CASE (7); xi_out= GP1; eta_out= GP1; zeta_out= GP1; w_out=1.0_wp
      CASE (8); xi_out=-GP1; eta_out= GP1; zeta_out= GP1; w_out=1.0_wp
      CASE DEFAULT
        xi_out=0.0_wp; eta_out=0.0_wp; zeta_out=0.0_wp; w_out=0.0_wp
      END SELECT
    END SUBROUTINE Elem_XXX_Get_Gauss_Point

    SUBROUTINE Elem_XXX_Shape_Functions(xi_in, eta_in, zeta_in, N_out)
      REAL(wp), INTENT(IN)  :: xi_in, eta_in, zeta_in
      REAL(wp), INTENT(OUT) :: N_out(:)
      N_out = 0.0_wp
      IF (SIZE(N_out) < 8) RETURN
      N_out(1) = 0.125_wp*(1.0_wp-xi_in)*(1.0_wp-eta_in)*(1.0_wp-zeta_in)
      N_out(2) = 0.125_wp*(1.0_wp+xi_in)*(1.0_wp-eta_in)*(1.0_wp-zeta_in)
      N_out(3) = 0.125_wp*(1.0_wp+xi_in)*(1.0_wp+eta_in)*(1.0_wp-zeta_in)
      N_out(4) = 0.125_wp*(1.0_wp-xi_in)*(1.0_wp+eta_in)*(1.0_wp-zeta_in)
      N_out(5) = 0.125_wp*(1.0_wp-xi_in)*(1.0_wp-eta_in)*(1.0_wp+zeta_in)
      N_out(6) = 0.125_wp*(1.0_wp+xi_in)*(1.0_wp-eta_in)*(1.0_wp+zeta_in)
      N_out(7) = 0.125_wp*(1.0_wp+xi_in)*(1.0_wp+eta_in)*(1.0_wp+zeta_in)
      N_out(8) = 0.125_wp*(1.0_wp-xi_in)*(1.0_wp+eta_in)*(1.0_wp+zeta_in)
    END SUBROUTINE Elem_XXX_Shape_Functions

    SUBROUTINE Elem_XXX_Jacobian(coords_in, N_in, xi_in, eta_in, zeta_in, &
        dNdX_out, detJ_out)
      REAL(wp), INTENT(IN)  :: coords_in(:,:), N_in(:)
      REAL(wp), INTENT(IN)  :: xi_in, eta_in, zeta_in
      REAL(wp), INTENT(OUT) :: dNdX_out(:,:), detJ_out
      dNdX_out = 0.0_wp
      detJ_out = 1.0_wp
    END SUBROUTINE Elem_XXX_Jacobian

    SUBROUTINE Elem_XXX_B_Matrix(dNdX_in, B_out)
      REAL(wp), INTENT(IN)  :: dNdX_in(:,:)
      REAL(wp), INTENT(OUT) :: B_out(:,:)
      B_out = 0.0_wp
    END SUBROUTINE Elem_XXX_B_Matrix

  END SUBROUTINE PH_Elem_XXX_API

END MODULE PH_Elem_XXX
