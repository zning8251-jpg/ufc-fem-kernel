!===============================================================================
! MODULE: PH_Elem_Porous
! LAYER:  L4_PH
! DOMAIN: Element/Porous
! ROLE:   Proc
! BRIEF:  Porous element unified interface
!===============================================================================
MODULE PH_Elem_Porous
!> [CORE] Porous element unified interface (merged Porous_Defn + Porous_Kernel)
  USE IF_Prec_Core, only: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  use IF_Mem_WS, only: RT_Elem_WS_GetPoroCapacity
  use MD_Base_ElemLib
  use MD_Base_ObjModel, only: MatCtxLegacy, MatRes, MatProps, IPState
  use MD_Base_State_API
  use MD_Model_Mgr
  USE MD_Elem_Mgr, only: ElemType, ElemFormul, ElemCtx, ElemFlags, ElemState, ShapeFuncResult
  USE MD_Mat_Lib, only: MatProperties
  use PH_ElemDiffUtils, only: DiffGauss
  use UF_Elem_Continuum_Struct
  use UF_Element_Base
  use UF_Material_Base
  use UF_RT_FieldMaterialFacade

  implicit none
  private

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  public :: UF_Elem_Porous_Calc
  public :: Calc_Pore_Saturated
  public :: Calc_Pore_TwoPhase
  public :: UF_Init_Pore_Saturated
  public :: UF_Init_Pore_TwoPhase
  public :: PH_Elem_Porous_Material_Update_TwoPhase_Routed

  !=============================================================================
  ! INTF-001 Arg TYPE
  !=============================================================================
  PUBLIC :: PH_Elem_Porous_Args
  TYPE :: PH_Elem_Porous_Args
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
  REAL(wp)              :: k_hyd       = 0.0_wp  ! hydraulic permeability scale
  REAL(wp)              :: alpha_b     = 1.0_wp ! Biot
  REAL(wp), POINTER     :: u_struct(:) => NULL()  ! packed structural displacement ptr
  REAL(wp), POINTER     :: p_pore(:)   => NULL()  ! nodal pore pressure ptr
  REAL(wp), POINTER     :: Kuu(:,:)    => NULL()  ! displacement-displacement block ptr
  REAL(wp), POINTER     :: Kpp(:,:)    => NULL()  ! pressure-pressure block ptr
  REAL(wp), POINTER     :: Kup(:,:)    => NULL()  ! displacement-pressure coupling block ptr
  REAL(wp), POINTER     :: ip_pore(:)  => NULL()  ! IP pore pressure ptr
  END TYPE PH_Elem_Porous_Args


contains

  !-----------------------------------------------------------------------------
  ! Subroutine: UF_Elem_Porous_Calc
  ! Purpose: Unified porous element calculation interface (RT_Elem_Core compatible)
  !-----------------------------------------------------------------------------
  SUBROUTINE UF_Elem_Porous_Calc(ElemType, Formul, Ctx, state_in, &
                                  Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(INOUT) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    CHARACTER(len=32) :: ename
    INTEGER(i4) :: nInt
    TYPE(UF_MaterialModel), ALLOCATABLE :: matModels(:)

    ename = ElemType%name
    CALL UPPER_CASE(ename)

    nInt = MAX(1_i4, ElemType%n_int_points)
    ALLOCATE(matModels(nInt))
    matModels(1:nInt) = Mat

    IF (INDEX(ename, 'SAT') > 0) THEN
      CALL Calc_Pore_Saturated(ElemType, Formul, Ctx, state_in, &
                               matModels, state_out, flags)
    ELSE IF (INDEX(ename, 'RCH') > 0) THEN
      CALL Calc_Pore_TwoPhase(ElemType, Formul, Ctx, state_in, &
                              matModels, state_out, flags)
    ELSE IF (INDEX(ename, 'P') > 0 .AND. &
             (INDEX(ename, 'C3D') > 0 .OR. INDEX(ename, 'CAX') > 0 .OR. &
              INDEX(ename, 'CPS') > 0 .OR. INDEX(ename, 'CPE') > 0)) THEN
      CALL Calc_Pore_Saturated(ElemType, Formul, Ctx, state_in, &
                               matModels, state_out, flags)
    ELSE
      CALL Calc_Pore_Saturated(ElemType, Formul, Ctx, state_in, &
                               matModels, state_out, flags)
    END IF

    DEALLOCATE(matModels)

  END SUBROUTINE UF_Elem_Porous_Calc

  SUBROUTINE UPPER_CASE(str)
    CHARACTER(len=*), INTENT(INOUT) :: str
    INTEGER(i4) :: i
    DO i = 1, LEN(str)
      IF (str(i:i) >= 'a' .AND. str(i:i) <= 'z') THEN
        str(i:i) = CHAR(ICHAR(str(i:i)) - 32)
      END IF
    END DO
  END SUBROUTINE UPPER_CASE

  SUBROUTINE PH_Elem_Porous_Material_Update_TwoPhase_Routed(rt_ctx, mat_slot, &
                                                            model_flag, alpha_vg, n_vg, &
                                                            phi, Swr, Snr, n_corey, &
                                                            m_vg, l_mualem, status)
    USE IF_Mat_Dispatch_Def, ONLY: RT_Mat_Dispatch_Ctx
    USE PH_Mat_Def, ONLY: PH_Mat_Slot
    USE PH_Elem_MaterialRoute, ONLY: PH_Elem_MatRoute_PorousTwoPhase

    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(OUT)   :: model_flag
    REAL(wp),                  INTENT(OUT)   :: alpha_vg
    REAL(wp),                  INTENT(OUT)   :: n_vg
    REAL(wp),                  INTENT(OUT)   :: phi
    REAL(wp),                  INTENT(OUT)   :: Swr
    REAL(wp),                  INTENT(OUT)   :: Snr
    REAL(wp),                  INTENT(OUT)   :: n_corey
    REAL(wp),                  INTENT(OUT)   :: m_vg
    REAL(wp),                  INTENT(OUT)   :: l_mualem
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_MatRoute_PorousTwoPhase(rt_ctx, mat_slot, model_flag, alpha_vg, &
                                         n_vg, phi, Swr, Snr, n_corey, m_vg, &
                                         l_mualem, status)
  END SUBROUTINE PH_Elem_Porous_Material_Update_TwoPhase_Routed

  !-----------------------------------------------------------------------------
  ! Calc_Pore_Saturated
  !-----------------------------------------------------------------------------
  subroutine Calc_Pore_Saturated(ElemType, Formul, Ctx, state_in, &
                                    matModels, state_out, flags)
    type(ElemType),       intent(in)    :: ElemType
    type(ElemFormul), intent(in)    :: Formul
    type(ElemCtx),    intent(in)    :: Ctx
    type(ElemState),         intent(in)    :: state_in
    type(UF_MaterialModel),  intent(in)    :: matModels(:)
    type(ElemState),         intent(inout) :: state_out
    type(ElemFlags),      intent(out)   :: flags

    integer(i4) :: nNode
    integer(i4) :: iNode, jNode
    integer(i4) :: rowP, colP

    real(wp), allocatable :: Ke(:,:), Re(:), Me(:,:), Ce(:,:)
    real(wp), pointer     :: Spp(:,:)

    real(wp), allocatable :: p_new(:), p_old(:)

    real(wp) :: k_hyd, S_s, dt
    real(wp) :: alpha_b_dummy, rho_fluid_dummy, cp_fluid_dummy, flag_vol_dummy
    type(UF_PoroPointState) :: prState
    integer(i4) :: ierr_material

    logical :: hasPoreField, hasPoreIncr, hasTransient
    logical :: ignoreCapacity, effHasTransient

    nNode = ElemType%pop%n_nodes

    call UF_Element_InitLocalMatrices(ElemType, 1_i4, Ke, Re, Me, Ce, flags)

    call UF_RT_Poro_MakeCoeffsFromContext(matModels(1), Ctx, alpha_b_dummy, k_hyd, S_s, &
                                          rho_fluid_dummy, cp_fluid_dummy, flag_vol_dummy, &
                                          hasTransient, prState, ierr_material)

    dt = max(Ctx%dTime, 0.0_wp)

    hasPoreField = allocated(Ctx%pore)
    hasPoreIncr  = allocated(Ctx%pore_incr)
    hasTransient = (S_s > 0.0_wp .and. dt > 0.0_wp .and. hasPoreField .and. hasPoreIncr)

    ignoreCapacity  = Ctx%ignoreCapacity
    effHasTransient = hasTransient .and. .not. ignoreCapacity

    call RT_Elem_WS_GetPoroCapacity(nNode, Spp)

    call DiffGauss(ElemType, Formul, Ctx, &
                                        Ctx%pore, Ctx%pore_incr, effHasTransient, &
                                        PoreSat_IpCoeffs, Ke, Spp)

    if (hasPoreField) then
      if (size(Ctx%pore) >= nNode) then
        do iNode = 1, nNode
          rowP = iNode
          if (rowP < 1 .or. rowP > size(Re)) cycle
          do jNode = 1, nNode
            colP = jNode
            if (colP < 1 .or. colP > size(Ke,2)) cycle
            Re(rowP) = Re(rowP) + Ke(rowP, colP) * Ctx%pore(jNode)
          end do
        end do
      end if
    end if

    if (effHasTransient) then

      allocate(p_new(nNode), p_old(nNode))
      do jNode = 1, nNode
        if (jNode <= size(Ctx%pore)) then
          p_new(jNode) = Ctx%pore(jNode)
        else
          p_new(jNode) = 0.0_wp
        end if
        if (jNode <= size(Ctx%pore_incr)) then
          p_old(jNode) = p_new(jNode) - Ctx%pore_incr(jNode)
        else
          p_old(jNode) = p_new(jNode)
        end if
      end do

      do iNode = 1, nNode
        rowP = iNode
        if (rowP < 1 .or. rowP > size(Re)) cycle
        do jNode = 1, nNode
          colP = jNode
          if (colP < 1 .or. colP > size(Ke,2)) cycle
          Ke(rowP, colP) = Ke(rowP, colP) + Spp(iNode, jNode) / dt
          Re(rowP)       = Re(rowP)       + (Spp(iNode, jNode) / dt) * &
                                         (p_new(jNode) - p_old(jNode))
        end do
      end do

      deallocate(p_new, p_old)
    end if

    call UF_Element_WriteBackMatrices(ElemType, 1_i4, Ke, Re, Me, Ce, state_out)

    state_out%failed   = flags%failed
    state_out%stableDt = flags%stableDt

  contains

    subroutine PoreSat_IpCoeffs(ip, sf, field_ip, field_old_ip, k_eff_ip, C_eff_ip)
      integer(i4), intent(in) :: ip
      type(ShapeFuncResult), intent(in) :: sf
      real(wp), intent(in)  :: field_ip
      real(wp), intent(in)  :: field_old_ip
      real(wp), intent(out) :: k_eff_ip
      real(wp), intent(out) :: C_eff_ip

      k_eff_ip = k_hyd
      if (effHasTransient) then
        C_eff_ip = S_s
      else
        C_eff_ip = 0.0_wp
      end if

    end subroutine PoreSat_IpCoeffs

  end subroutine Calc_Pore_Saturated

  !-----------------------------------------------------------------------------
  ! Calc_Pore_TwoPhase
  !-----------------------------------------------------------------------------
  subroutine Calc_Pore_TwoPhase(ElemType, Formul, Ctx, state_in, &
                                   matModels, state_out, flags)
    type(ElemType),       intent(in)    :: ElemType
    type(ElemFormul), intent(in)    :: Formul
    type(ElemCtx),    intent(in)    :: Ctx
    type(ElemState),         intent(in)    :: state_in
    type(UF_MaterialModel),  intent(in)    :: matModels(:)
    type(ElemState),         intent(inout) :: state_out
    type(ElemFlags),      intent(out)   :: flags

    integer(i4) :: nNode
    integer(i4) :: iNode, jNode
    integer(i4) :: rowP, colP

    real(wp), allocatable :: Ke(:,:), Re(:), Me(:,:), Ce(:,:)
    real(wp), pointer     :: Cpp(:,:)

    real(wp), allocatable :: p_new(:), p_old(:)

    real(wp) :: k_hyd, phi, dt
    logical  :: ignoreCapacity, effHasTransient

    real(wp) :: model_flag, alpha_vg, n_vg, m_vg, l_mualem
    real(wp) :: Swr, Snr, n_corey
    integer(i4) :: intModel
    type(MatProperties) :: props
    type(UF_PoroPointState) :: prState
    real(wp) :: alpha_b_dummy, S_s_dummy, rho_fluid_dummy, cp_fluid_dummy, flag_vol_dummy
    integer(i4) :: ierr_material

    logical :: hasPoreField, hasPoreIncr, hasTransient

    nNode = ElemType%pop%n_nodes

    call UF_Element_InitLocalMatrices(ElemType, 1_i4, Ke, Re, Me, Ce, flags)

    props = matModels(1)%props

    k_hyd      = 0.0_wp
    phi        = 0.0_wp
    model_flag = 0.0_wp
    alpha_vg   = 0.0_wp
    n_vg       = 0.0_wp
    m_vg       = 0.0_wp
    l_mualem   = 0.5_wp
    Swr        = 0.0_wp
    Snr        = 0.0_wp
    n_corey    = 2.0_wp

    alpha_b_dummy   = 0.0_wp
    S_s_dummy       = 0.0_wp
    rho_fluid_dummy = 0.0_wp
    cp_fluid_dummy  = 0.0_wp
    flag_vol_dummy  = 0.0_wp

    call UF_RT_Poro_MakeCoeffsFromContext(matModels(1), Ctx, alpha_b_dummy, k_hyd, S_s_dummy, &
                                          rho_fluid_dummy, cp_fluid_dummy, flag_vol_dummy, &
                                          hasTransient, prState, ierr_material)

    if (allocated(props%props)) then
      if (size(props%props) >= MATERIAL_IDX_TWOPH_MODEL)    model_flag = props%props(MATERIAL_IDX_TWOPH_MODEL)
      if (size(props%props) >= MATERIAL_IDX_VG_ALPHA)       alpha_vg   = props%props(MATERIAL_IDX_VG_ALPHA)
      if (size(props%props) >= MATERIAL_IDX_VG_N)           n_vg       = props%props(MATERIAL_IDX_VG_N)
      if (size(props%props) >= MATERIAL_IDX_PHI)            phi        = props%props(MATERIAL_IDX_PHI)
      if (size(props%props) >= MATERIAL_IDX_COREY_SWIR)     Swr        = props%props(MATERIAL_IDX_COREY_SWIR)
      if (size(props%props) >= MATERIAL_IDX_COREY_SNIR)     Snr        = props%props(MATERIAL_IDX_COREY_SNIR)
      if (size(props%props) >= MATERIAL_IDX_COREY_NW)       n_corey    = props%props(MATERIAL_IDX_COREY_NW)
      if (size(props%props) >= MATERIAL_IDX_VG_M)           m_vg       = props%props(MATERIAL_IDX_VG_M)
      if (size(props%props) >= MATERIAL_IDX_MUALEM_L)       l_mualem   = props%props(MATERIAL_IDX_MUALEM_L)
    end if

    if (phi <= 0.0_wp)      phi      = 0.3_wp
    if (alpha_vg <= 0.0_wp) alpha_vg = 1.0_wp
    if (n_vg <= 1.0_wp)     n_vg     = 2.0_wp
    if (m_vg <= 0.0_wp)     m_vg     = 1.0_wp - 1.0_wp / n_vg
    if (n_corey <= 0.0_wp)  n_corey  = 2.0_wp

    intModel = 1
    if (model_flag >= 1.5_wp) intModel = 2

    dt = max(Ctx%dTime, 0.0_wp)

    hasPoreField = allocated(Ctx%pore)
    hasPoreIncr  = allocated(Ctx%pore_incr)

    hasTransient = (phi > 0.0_wp .and. dt > 0.0_wp .and. hasPoreField .and. hasPoreIncr)

    ignoreCapacity  = Ctx%ignoreCapacity
    effHasTransient = hasTransient .and. .not. ignoreCapacity

    call RT_Elem_WS_GetPoroCapacity(nNode, Cpp)

    call DiffGauss(ElemType, Formul, Ctx, &
                                        Ctx%pore, Ctx%pore_incr, effHasTransient, &
                                        PoreTwo_IpCoeffs, Ke, Cpp)

    if (hasPoreField) then
      if (size(Ctx%pore) >= nNode) then
        do iNode = 1, nNode
          rowP = iNode
          if (rowP < 1 .or. rowP > size(Re)) cycle
          do jNode = 1, nNode
            colP = jNode
            if (colP < 1 .or. colP > size(Ke,2)) cycle
            Re(rowP) = Re(rowP) + Ke(rowP, colP) * Ctx%pore(jNode)
          end do
        end do
      end if
    end if

    if (effHasTransient) then

      allocate(p_new(nNode), p_old(nNode))
      do jNode = 1, nNode
        if (jNode <= size(Ctx%pore)) then
          p_new(jNode) = Ctx%pore(jNode)
        else
          p_new(jNode) = 0.0_wp
        end if
        if (jNode <= size(Ctx%pore_incr)) then
          p_old(jNode) = p_new(jNode) - Ctx%pore_incr(jNode)
        else
          p_old(jNode) = p_new(jNode)
        end if
      end do

      do iNode = 1, nNode
        rowP = iNode
        if (rowP < 1 .or. rowP > size(Re)) cycle
        do jNode = 1, nNode
          colP = jNode
          if (colP < 1 .or. colP > size(Ke,2)) cycle
          Ke(rowP, colP) = Ke(rowP, colP) + Cpp(iNode, jNode) / dt
          Re(rowP)       = Re(rowP)       + (Cpp(iNode, jNode) / dt) * &
                                         (p_new(jNode) - p_old(jNode))
        end do
      end do

      deallocate(p_new, p_old)
    end if

    call UF_Element_WriteBackMatrices(ElemType, 1_i4, Ke, Re, Me, Ce, state_out)

    state_out%failed   = flags%failed
    state_out%stableDt = flags%stableDt

  contains

    subroutine PoreTwo_IpCoeffs(ip, sf, field_ip, field_old_ip, k_eff_ip, C_eff_ip)
      integer(i4), intent(in) :: ip
      type(ShapeFuncResult), intent(in) :: sf
      real(wp), intent(in)  :: field_ip
      real(wp), intent(in)  :: field_old_ip
      real(wp), intent(out) :: k_eff_ip
      real(wp), intent(out) :: C_eff_ip

      real(wp) :: S_ip, dSdp_ip, k_rel_ip

      call eval_saturation_and_kr(field_ip, intModel, alpha_vg, n_vg, m_vg, l_mualem, &
                                  Swr, Snr, n_corey, S_ip, dSdp_ip, k_rel_ip)

      k_eff_ip = k_hyd * k_rel_ip
      C_eff_ip = 0.0_wp
      if (effHasTransient) then
        C_eff_ip = phi * dSdp_ip
      end if

    end subroutine PoreTwo_IpCoeffs

  end subroutine Calc_Pore_TwoPhase

  !-----------------------------------------------------------------------------
  ! eval_saturation_and_kr
  !-----------------------------------------------------------------------------
  subroutine eval_saturation_and_kr(p, intModel, alpha_vg, n_vg, m_vg, l_mualem, &
                                    Swr, Snr, n_corey, S, dSdp, k_rel)

    real(wp), intent(in)  :: p
    integer(i4), intent(in) :: intModel
    real(wp), intent(in)  :: alpha_vg, n_vg, m_vg, l_mualem
    real(wp), intent(in)  :: Swr, Snr, n_corey
    real(wp), intent(out) :: S, dSdp, k_rel

    real(wp) :: pc, Se, dSedpc, t, X, Se_eff, one_minus_sumre

    one_minus_sumre = max(1.0_wp - Swr - Snr, 1.0e-8_wp)

    pc = max(-p, 0.0_wp)

    if (pc <= 0.0_wp) then
      S    = 1.0_wp
      dSdp = 0.0_wp
      k_rel= 1.0_wp
      return
    end if

    select case (intModel)
    case (1)

      t  = max(alpha_vg * pc, 1.0e-12_wp)
      Se = t**(-n_corey)
      Se = min(max(Se, 0.0_wp), 1.0_wp)

      dSedpc = -n_corey * t**(-n_corey-1) * alpha_vg

      S = Swr + Se * one_minus_sumre
      dSdp = -one_minus_sumre * dSedpc

      k_rel = Se**n_corey

    case (2)

      t  = max(alpha_vg * pc, 1.0e-12_wp)
      X  = t**n_vg
      Se = (1.0_wp + X)**(-m_vg)
      Se = min(max(Se, 0.0_wp), 1.0_wp)

      dSedpc = -m_vg * (1.0_wp+X)**(-m_vg-1) * (n_vg * alpha_vg * t**(n_vg-1))

      S = Swr + Se * one_minus_sumre
      dSdp = -one_minus_sumre * dSedpc

      Se_eff = min(max(Se, 0.0_wp), 1.0_wp)

      if (Se_eff <= 0.0_wp) then
        k_rel = 0.0_wp
      else
        t     = Se_eff**(1.0_wp/m_vg)
        t     = max(min(t, 1.0_wp), 0.0_wp)
        X     = 1.0_wp - (1.0_wp - t)**m_vg
        k_rel = Se_eff**l_mualem * X*X
      end if

    case default

      S    = 1.0_wp
      dSdp = 0.0_wp
      k_rel= 1.0_wp
    end select

  end subroutine eval_saturation_and_kr

  !-----------------------------------------------------------------------------
  ! UF_Init_Pore_Saturated
  !-----------------------------------------------------------------------------
  subroutine UF_Init_Pore_Saturated(Element, name)
    type(ElemType), intent(inout) :: Element
    character(len=*),     intent(in)    :: name

    call UF_Init_Continuum(Element, trim(name))

    Element%name        = trim(name)
    Element%compute     => Calc_Pore_Saturated
    Element%nDOFPerNode = 1

    Element%has_struct  = .false.
    Element%has_thermal = .false.
    Element%has_pore    = .true.

  end subroutine UF_Init_Pore_Saturated

  !-----------------------------------------------------------------------------
  ! UF_Init_Pore_TwoPhase
  !-----------------------------------------------------------------------------
  subroutine UF_Init_Pore_TwoPhase(Element, name)
    type(ElemType), intent(inout) :: Element
    character(len=*),     intent(in)    :: name

    call UF_Init_Continuum(Element, trim(name))

    Element%name        = trim(name)
    Element%compute     => Calc_Pore_TwoPhase
    Element%nDOFPerNode = 1

    Element%has_struct  = .false.
    Element%has_thermal = .false.
    Element%has_pore    = .true.

  end subroutine UF_Init_Pore_TwoPhase

END MODULE PH_Elem_Porous

