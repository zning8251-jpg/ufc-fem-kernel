!===============================================================================
! MODULE: PH_ElemRT_Brg
! LAYER:  L4_PH
! DOMAIN: Element/Shared
! ROLE:   Brg
! BRIEF:  Bridge module for geometric nonlinearity operations
!===============================================================================
MODULE PH_ElemRT_Brg
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE IF_Prec_Core, ONLY: wp, i4
  ! ARCHITECTURE FIX (N1-3): Import from L4_PH instead of L5_RT (reverse dependency violation)
  USE PH_NLGeom_Eval, ONLY: RT_LagrCfg, PH_NLGeom_TotLag, PH_NLGeom_UpdLag
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! Export RT layer types for L4_PH use (type aliases)
  !=============================================================================

  !> @brief RT_LagrCfg type alias (re-exported from RT layer)
  ! Bridge module exports RT layer types directly for L4_PH use
  ! This avoids wrapper overhead while maintaining dependency isolation
  PUBLIC :: RT_LagrCfg

  !=============================================================================
  ! Bridge function interfaces (maintain same signature as RT layer)
  !=============================================================================

  PUBLIC :: PH_RT_Elem_GeomNonlin_TotLag
  PUBLIC :: PH_RT_Elem_GeomNonlin_UpdLag

  !=============================================================================
  ! INTF-001 Arg TYPE
  !=============================================================================
  PUBLIC :: PH_Elem_Shared_Args

  !=============================================================================
  ! INTF-002 Element Compute Facade (Golden Thread)
  !=============================================================================
  PUBLIC :: PH_Elem_Compute

  TYPE :: PH_Elem_Shared_Args
  ! Purpose: ShapeFunc/JacB/FormStiffMatrix/FormIntForce/NL_TL/NL_UL/
  !          ApplyConstraint/ApplyMPC/FormContactContrib/FormContactFaceCtr/
  ! FormBodyForce/FormNodalForce/CollectIPVars
  ! Theory: Standard FE weak form and B-matrix; Zienkiewicz & Taylor; Bathe FE Procedures.
  ! Status: INTF-001 Progressive Refactoring
  INTEGER(i4)           :: n_node      = 0_i4  ! nodes per element
  INTEGER(i4)           :: n_dof       = 0_i4  ! DoFs per element
  INTEGER(i4)           :: n_ip        = 0_i4  ! integration points per element
  INTEGER(i4)           :: load_type   = 0_i4  ! load kind / case id
  INTEGER(i4)           :: ctype       = 0_i4  ! constraint or cell type code
  INTEGER(i4)           :: face_id     = 0_i4  ! face / surface id
  INTEGER(i4)           :: idof        = 0_i4  ! local DoF index
  REAL(wp)              :: xi          = 0.0_wp  ! parametric coordinate xi
  REAL(wp)              :: eta         = 0.0_wp
  REAL(wp)              :: zeta        = 0.0_wp
  REAL(wp)              :: detJ        = 0.0_wp ! Jacobian
  REAL(wp)              :: penalty     = 0.0_wp  ! penalty factor
  REAL(wp)              :: val         = 0.0_wp  ! prescribed scalar value
  REAL(wp)              :: bx          = 0.0_wp  ! grid index x (hash)
  REAL(wp)              :: by          = 0.0_wp  ! grid index y (hash)
  REAL(wp)              :: bz          = 0.0_wp  ! grid index z (hash)
  REAL(wp), POINTER     :: coords(:,:) => NULL() ! (3,n_node)
  REAL(wp), POINTER     :: u_elem(:)   => NULL()  ! element displacement vector ptr
  REAL(wp), POINTER     :: D(:,:)      => NULL()  ! material stiffness (elasticity) matrix ptr
  REAL(wp), POINTER     :: Ke(:,:)     => NULL()  ! element stiffness matrix ptr
  REAL(wp), POINTER     :: F_eq(:)     => NULL()  ! equivalent nodal force ptr
  REAL(wp), POINTER     :: N(:)        => NULL()  ! shape-function matrix ptr
  REAL(wp), POINTER     :: dNdx(:,:)   => NULL()  ! shape-function spatial derivatives ptr
  REAL(wp), POINTER     :: B(:,:)      => NULL()  ! strain-displacement operator ptr
  REAL(wp), POINTER     :: Ke_geo(:,:) => NULL()  ! geometric stiffness contribution ptr
  REAL(wp), POINTER     :: R_int(:)    => NULL()  ! internal residual ptr
  REAL(wp), POINTER     :: ip_stress(:,:) => NULL()  ! IP stress pack ptr
  REAL(wp), POINTER     :: ip_strain(:,:) => NULL()  ! IP strain pack ptr
  REAL(wp), POINTER     :: ip_peeq(:)  => NULL()  ! IP equivalent plastic strain ptr
  REAL(wp), POINTER     :: out_vars(:,:) => NULL()  ! output variable mask / ids ptr
  END TYPE PH_Elem_Shared_Args


CONTAINS

  !=============================================================================
  !> @brief Total Lagrangian formulation (Bridge interface)
  !! @details Bridges L4_PH to PH_NLGeom implementation (N1-3 architecture fix)
  !! @note Architecture fix: Route to L4_PH instead of L5_RT (reverse dependency violation)
  !=============================================================================
  SUBROUTINE PH_RT_Elem_GeomNonlin_TotLag(config, F, E, S, K_mat, K_geo, status, R_elem, D_tangent)
    TYPE(RT_LagrCfg), INTENT(IN) :: config
    REAL(wp), INTENT(INOUT) :: F(3, 3)
    REAL(wp), INTENT(INOUT) :: E(3, 3)
    REAL(wp), INTENT(IN) :: S(3, 3)
    REAL(wp), INTENT(OUT) :: K_mat(:,:)
    REAL(wp), INTENT(OUT) :: K_geo(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), INTENT(OUT), OPTIONAL :: R_elem(:)
    REAL(wp), INTENT(IN), OPTIONAL :: D_tangent(6, 6)

    ! ARCHITECTURE FIX (N1-3): Route to L4_PH implementation
    IF (PRESENT(R_elem) .AND. PRESENT(D_tangent)) THEN
      CALL PH_NLGeom_TotLag(config, F, E, S, K_mat, K_geo, status, R_elem, D_tangent)
    ELSE IF (PRESENT(R_elem)) THEN
      CALL PH_NLGeom_TotLag(config, F, E, S, K_mat, K_geo, status, R_elem)
    ELSE
      CALL PH_NLGeom_TotLag(config, F, E, S, K_mat, K_geo, status)
    END IF

  END SUBROUTINE PH_RT_Elem_GeomNonlin_TotLag

  !=============================================================================
  !> @brief Updated Lagrangian formulation (Bridge interface)
  !! @details Bridges L4_PH to PH_NLGeom implementation (N1-3 architecture fix)
  !! @note Architecture fix: Route to L4_PH instead of L5_RT (reverse dependency violation)
  !=============================================================================
  SUBROUTINE PH_RT_Elem_GeomNonlin_UpdLag(config, F, epsilon, sigma, K_mat, K_geo, status, R_elem, D_tangent)
    TYPE(RT_LagrCfg), INTENT(IN) :: config
    REAL(wp), INTENT(INOUT) :: F(3, 3)
    REAL(wp), INTENT(INOUT) :: epsilon(3, 3)
    REAL(wp), INTENT(IN) :: sigma(3, 3)
    REAL(wp), INTENT(OUT) :: K_mat(:,:)
    REAL(wp), INTENT(OUT) :: K_geo(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), INTENT(OUT), OPTIONAL :: R_elem(:)
    REAL(wp), INTENT(IN), OPTIONAL :: D_tangent(6, 6)

    ! ARCHITECTURE FIX (N1-3): Route to L4_PH implementation
    IF (PRESENT(R_elem) .AND. PRESENT(D_tangent)) THEN
      CALL PH_NLGeom_UpdLag(config, F, epsilon, sigma, K_mat, K_geo, status, R_elem, D_tangent)
    ELSE IF (PRESENT(R_elem)) THEN
      CALL PH_NLGeom_UpdLag(config, F, epsilon, sigma, K_mat, K_geo, status, R_elem)
    ELSE
      CALL PH_NLGeom_UpdLag(config, F, epsilon, sigma, K_mat, K_geo, status)
    END IF

  END SUBROUTINE PH_RT_Elem_GeomNonlin_UpdLag

  !=============================================================================
  !> @brief Element Facade (Golden Thread)
  !> @details Dispatches execution to specific element algorithm based on element family/type
  !=============================================================================
  SUBROUTINE PH_Elem_Compute(elem_cfg, elem_state, elem_ctx, mat_cfg, status)
    USE PH_Elem_Def, ONLY: PH_Elem_Desc, PH_Elem_Ctx
    USE MD_Field_Mgr, ONLY: MD_ElemIPData
    USE MD_Mat_BaseDef, ONLY: MD_Mat_Ctx
    USE PH_Elem_Reg, ONLY: PH_ELEM_FAMILY_SOLID_2D, PH_ELEM_FAMILY_SOLID_3D
    USE PH_Elem_CPE4, ONLY: PH_Elem_CPE4_NL_TL_Structured
    USE PH_Elem_CPS4, ONLY: PH_Elem_CPS4_NL_TL_Structured
    USE PH_Elem_C3D8, ONLY: PH_Elem_C3D8_NL_TL_Structured

    TYPE(PH_Elem_Desc), INTENT(IN) :: elem_cfg
    TYPE(MD_ElemIPData), INTENT(INOUT) :: elem_state
    TYPE(PH_Elem_Ctx), INTENT(INOUT) :: elem_ctx
    TYPE(MD_Mat_Ctx), INTENT(IN) :: mat_cfg
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    status%status_code = IF_STATUS_OK

    ! Dispatch based on family ID and node count
    SELECT CASE (elem_cfg%cfg%family_id)
      CASE (PH_ELEM_FAMILY_SOLID_2D)
        IF (elem_cfg%pop%n_nodes == 4) THEN
          ! Here we should actually distinguish CPE4 vs CPS4 using elem_type
          ! For now, if nshr==1 we assume Plane Stress (CPS4), else Plane Strain (CPE4)
          IF (mat_cfg%nshr == 1) THEN
             CALL PH_Elem_CPS4_NL_TL_Structured(elem_cfg, elem_state, elem_ctx, mat_cfg, status)
          ELSE
             CALL PH_Elem_CPE4_NL_TL_Structured(elem_cfg, elem_state, elem_ctx, mat_cfg, status)
          END IF
        ELSE
          status%status_code = -1
        END IF
      CASE (PH_ELEM_FAMILY_SOLID_3D)
        IF (elem_cfg%pop%n_nodes == 8) THEN
          CALL PH_Elem_C3D8_NL_TL_Structured(elem_cfg, elem_state, elem_ctx, mat_cfg, status)
        ELSE
          status%status_code = -1
        END IF
      CASE DEFAULT
        status%status_code = -1
    END SELECT

  END SUBROUTINE PH_Elem_Compute

END MODULE PH_ElemRT_Brg

