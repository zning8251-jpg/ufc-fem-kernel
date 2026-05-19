!===============================================================================
! MODULE: PH_ElemContm_Ops
! LAYER:  L4_PH
! DOMAIN: Element
! ROLE:   Proc
! BRIEF:  Continuum element unified computation module
!===============================================================================
MODULE PH_ElemContm_Ops
!> [CORE] Continuum element unified computation module
!> Theory: K = integral B^T*D*B dV, R_int = integral B^T*sigma dV, B-bar method
!> Status: Production | Last verified: 2026-02-28

  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  use IF_Mem_WS, only: GetStructWS, RT_Elem_WS_GetMultiField, RT_Elem_WS_GetStructBm_2
  use MD_Base_ElemLib
  use MD_Base_State_API
    use MD_Model_Mgr
  USE MD_Elem_Types, ONLY: ShapeFuncResult
  USE MD_Elem_Mgr, only: ElemType, ElemFormul, ElemCtx, ElemFlags, IPState, ElemState
  USE MD_Field_Mgr
  use MD_Out_UniFld
  use UF_Continuum_Struct_BBar
  use UF_Continuum_Struct_Material
  use UF_Elem_Continuum_Struct
  use UF_Element_Base, only: UF_ElemType, UF_ElemFormul, UF_ElemCtx, UF_ElemFlags
  use UF_GaussQuad
  use UF_Material_Base, only: UF_MaterialModel
  use UF_MaterialStateTypes
  use UF_ShapeFunc

  implicit none
  private

  !=============================================================================
  ! PUBLIC TYPES AND SUBROUTINES
  !=============================================================================
  ! Structured interfaces (new)
  PUBLIC :: PH_Elem_Contm_Calc3D_Arg
  PUBLIC :: PH_Elem_Contm_Calc3D
  PUBLIC :: PH_Elem_Contm_Calc3D_Structured
  
  ! Legacy interfaces (kept for backward compatibility)
  ! CompPoro / CompThm / CompTHM are re-export aliases in PH_ElemContm_Algo.f90
  PUBLIC :: Calc_C3D20R
  PUBLIC :: Calc_C3D8R
  PUBLIC :: Calc_Continuum
  PUBLIC :: Calc_Continuum2D
  PUBLIC :: Calc_Continuum2D_THM
  PUBLIC :: Calc_Continuum2D_Thermal
  PUBLIC :: Calc_Continuum3D
  PUBLIC :: Calc_Continuum3D_Reduced
  PUBLIC :: Calc_Continuum3D_THM
  PUBLIC :: Calc_Continuum3D_Thermal
  PUBLIC :: Calc_Continuum_Poro
  PUBLIC :: Calc_Continuum_THM
  PUBLIC :: Calc_Continuum_Thermal
  PUBLIC :: Calc_Continuum_MatProps
  PUBLIC :: Calc_ElementVolume_Hex
  PUBLIC :: Estimate_ElementVolume
  PUBLIC :: InitPoro
  PUBLIC :: InitTHM
  PUBLIC :: InitThm
  PUBLIC :: UF_Continuum_ApplyHourglass2D
  PUBLIC :: UF_Continuum_ApplyHourglass3D
  PUBLIC :: UF_Embed_StructBlock
  PUBLIC :: UF_Init_Continuum
  PUBLIC :: UF_Init_Continuum2D
  PUBLIC :: UF_Init_Continuum3D
  PUBLIC :: UF_Init_Continuum_Poro
  PUBLIC :: UF_Init_Continuum_THM
  PUBLIC :: UF_Init_Continuum_Thermal
  
  !=============================================================================
  ! INPUT/OUTPUT STRUCTURES FOR STRUCTURED INTERFACES
  !=============================================================================
  
  !> @brief Input structure for 3D continuum element calculation
  
  !> @brief Output structure for 3D continuum element calculation
  TYPE, PUBLIC :: PH_Elem_Contm_Calc3D_Arg
    TYPE(UF_ElemType) :: elem_type  ! Element type descriptor (Desc)                   ! [IN]
    TYPE(UF_ElemFormul) :: formul  ! Formulation parameters (Algo)                   ! [IN]
    TYPE(UF_ElemCtx) :: ctx  ! Element context (Ctx)                   ! [IN]
    TYPE(ElemState) :: state_in  ! Input element state (State)                   ! [IN]
    TYPE(UF_MaterialModel), ALLOCATABLE :: mat_models(:)  ! [IN] per-IP material pack
    TYPE(ElemState) :: state_out  ! Output element state (State)                   ! [OUT]
    TYPE(UF_ElemFlags) :: flags  ! Element flags and status (State)                   ! [OUT]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_Contm_Calc3D_Arg


  ! Generic: UF_* vs base ElemType overloads (same name would be illegal without interface)
  INTERFACE Calc_Continuum2D
    MODULE PROCEDURE Calc_Continuum2D_UF
    MODULE PROCEDURE Calc_Continuum2D_elem
  END INTERFACE Calc_Continuum2D
  PRIVATE :: Calc_Continuum2D_UF, Calc_Continuum2D_elem

contains

  !> Node count for MD_Elem_Algo%ElemType / UF_ElemType (both use %n_nodes on parent).
  PURE FUNCTION PH_Contm_NNodes_Base(et) RESULT(n)
    INTEGER(i4) :: n
    TYPE(ElemType), INTENT(IN) :: et
    n = et%pop%n_nodes
  END FUNCTION PH_Contm_NNodes_Base

  !> Copy UF formulation onto base ElemFormul (for Calc_Continuum / ContGauss).
  PURE SUBROUTINE PH_Contm_UF_Formul_to_ElemFormul(uf, ef)
    TYPE(UF_ElemFormul), INTENT(IN) :: uf
    TYPE(ElemFormul), INTENT(OUT) :: ef
    ef%formulationType = uf%formulationType
    ef%order = uf%order
    ef%nIntPoints = uf%nIntPoints
    ef%reducedintegrat = uf%reducedintegrat
    ef%hourglasscontro = uf%hourglasscontro
    ef%kineFormulation = uf%kineFormulation
    ef%integration_scheme = uf%integration_scheme
    ef%use_bbar = uf%use_bbar
    IF (uf%integration_scheme == UF_Int_Reduced) ef%reducedintegrat = .TRUE.
    IF (uf%integration_scheme == UF_Int_Selective) ef%hourglasscontro = .TRUE.
  END SUBROUTINE PH_Contm_UF_Formul_to_ElemFormul

  !> Base ElemFormul -> UF_ElemFormul (3D UF thermal/THM entry).
  PURE SUBROUTINE PH_Contm_ElemFormul_to_UF(ef, uf)
    TYPE(ElemFormul), INTENT(IN) :: ef
    TYPE(UF_ElemFormul), INTENT(OUT) :: uf
    uf%formulationType = ef%formulationType
    uf%order = ef%order
    uf%nIntPoints = ef%nIntPoints
    uf%reducedintegrat = ef%reducedintegrat
    uf%hourglasscontro = ef%hourglasscontro
    uf%kineFormulation = ef%kineFormulation
    uf%integration_scheme = ef%integration_scheme
    uf%use_bbar = ef%use_bbar
  END SUBROUTINE PH_Contm_ElemFormul_to_UF

  !> Promote base Desc/Ctx/Formul to UF_* for routines that require UF_ElemType (e.g. 3D thermal).
  SUBROUTINE PH_Contm_Promote_to_UF_Therm3D(et, fm, cx, et_uf, fm_uf, cx_uf)
    TYPE(ElemType), INTENT(IN) :: et
    TYPE(ElemFormul), INTENT(IN) :: fm
    TYPE(ElemCtx), INTENT(IN) :: cx
    TYPE(UF_ElemType), INTENT(OUT) :: et_uf
    TYPE(UF_ElemFormul), INTENT(OUT) :: fm_uf
    TYPE(UF_ElemCtx), INTENT(OUT) :: cx_uf
    et_uf = et
    CALL PH_Contm_ElemFormul_to_UF(fm, fm_uf)
    cx_uf = cx
  END SUBROUTINE PH_Contm_Promote_to_UF_Therm3D

  !> Copy UF_ElemFlags (extension) onto base ElemFlags (strict F2003 safe).
  PURE SUBROUTINE PH_Contm_ElemFlags_copy_UF_to_base(dst, src)
    TYPE(ElemFlags), INTENT(OUT) :: dst
    TYPE(UF_ElemFlags), INTENT(IN) :: src
    dst%failed = src%failed
    dst%suggest_cutback = src%suggest_cutback
    dst%requires_reasse = src%requires_reasse
    dst%stableDt = src%stableDt
    dst%status = src%status
    dst%stp%nlgeom = src%stp%nlgeom
    dst%formulation_typ = src%formulation_typ
  END SUBROUTINE PH_Contm_ElemFlags_copy_UF_to_base

  subroutine Calc_C3D20R(ElemType, Formul, Ctx, state_in, &
                            matModels, state_out, flags)
    !! Compute C3D20R element with reduced integration (8 IPs)
    !!
    !! Algorithm:
    !!   1. Compute base element response at 8 integration points
    !!   2. Apply hourglass control if needed
    
    type(UF_ElemType),        intent(in)    :: ElemType
    type(UF_ElemFormul), intent(in)    :: Formul
    type(UF_ElemCtx),     intent(in)    :: Ctx
    type(ElemState),       intent(in)    :: state_in
    type(UF_MaterialModel),      intent(in)    :: matModels(:)
    type(ElemState),       intent(inout) :: state_out
    type(UF_ElemFlags),       intent(out)   :: flags
    
    ! For C3D20R, use base computation with 8 integration points
    ! Hourglass control is less critical for quadratic elements
    call Calc_Continuum3D(ElemType, Formul, Ctx, state_in, &
                             matModels, state_out, flags)
    
  end subroutine Calc_C3D20R

  subroutine Calc_C3D8R(ElemType, Formul, Ctx, state_in, &
                           matModels, state_out, flags)
    !! Compute C3D8R element with reduced integration and hourglass control
    !!
    !! Algorithm:
    !!   1. Compute base element response at 1 integration point
    !!   2. Compute hourglass modes
    !!   3. Compute hourglass forces
    !!   4. Add hourglass forces to residual
    
    type(UF_ElemType),        intent(in)    :: ElemType
    type(UF_ElemFormul), intent(in)    :: Formul
    type(UF_ElemCtx),     intent(in)    :: Ctx
    type(ElemState),       intent(in)    :: state_in
    type(UF_MaterialModel),      intent(in)    :: matModels(:)
    type(ElemState),       intent(inout) :: state_out
    type(UF_ElemFlags),       intent(out)   :: flags
    
    ! Local variables
    ! Local variables
    real(wp) :: coords(8, 3)
    real(wp) :: h_mode(4)
    real(wp) :: Q_hg, E_hg
    real(wp) :: F_hg(8, 3)
    real(wp) :: rho, c_wave, V_elem, E, nu
    type(ErrorStatusType) :: status
    type(MatProperties) :: mat_props
    integer(i4) :: i
    
    ! Check if hourglass control is enabled
    if (.not. Formul%hourglasscontro) then
      ! Use base computation without hourglass control
      call Calc_Continuum3D(ElemType, Formul, Ctx, state_in, &
                               matModels, state_out, flags)
      return
    end if
    
    ! Extract element coordinates from Ctx
    if (.not. allocated(Ctx%coords_ref)) then
      ! Fallback to base computation if coordinates not available
      call Calc_Continuum3D(ElemType, Formul, Ctx, state_in, &
                               matModels, state_out, flags)
      return
    end if
    
    if (size(Ctx%coords_ref, 1) < 3 .or. size(Ctx%coords_ref, 2) < 8) then
      call Calc_Continuum3D(ElemType, Formul, Ctx, state_in, &
                               matModels, state_out, flags)
      return
    end if
    
    ! Extract coordinates (transpose: Ctx stores as (dim, nNode))
    do i = 1, 8
      coords(i, 1) = Ctx%coords_ref(1, i)
      coords(i, 2) = Ctx%coords_ref(2, i)
      coords(i, 3) = Ctx%coords_ref(3, i)
    end do
    
    ! Compute base element response (at 1 integration point)
    call Calc_Continuum3D(ElemType, Formul, Ctx, state_in, &
                             matModels, state_out, flags)
    
    if (flags%failed) return
    
    ! Extract Mat properties for hourglass stiffness
    if (size(matModels) > 0) then
      mat_props = matModels(1)%props
      if (allocated(mat_props%props)) then
        if (size(mat_props%props) >= 1) E = mat_props%props(1)
        if (size(mat_props%props) >= 2) nu = mat_props%props(2)
      end if
      rho = mat_props%density
    else
      rho = 1.0_wp
      E = 1.0_wp
      nu = 0.3_wp
    end if
    
    ! Compute wave speed: c = sqrt(E / rho)
    if (rho > 1.0e-30_wp .and. E > 1.0e-30_wp) then
      c_wave = sqrt(E / rho)
    else
      c_wave = 1.0_wp
    end if
    
    ! Compute element volume (simplified: use determinant of Jacobian at center)
    ! For hex element, volume ?det(J) at center point (0,0,0)
    call Calc_ElementVolume_Hex(coords, V_elem, status)
    if (status%status_code /= IF_STATUS_OK .or. V_elem <= 0.0_wp) then
      ! Fallback: estimate volume from bounding box
      V_elem = Estimate_ElementVolume(coords)
    end if
    
    ! Compute hourglass mode
    call RT_Hourglass_ComputeMode(coords, h_mode, status)
    if (status%status_code /= IF_STATUS_OK) return
    
    ! Compute hourglass stiffness
    call RT_Hourglass_ComputeStiff(rho, c_wave, V_elem, Q_hg, status)
    if (status%status_code /= IF_STATUS_OK) return
    
    ! Compute hourglass force
    call RT_Hourglass_ComputeForce(h_mode, Q_hg, F_hg, status)
    if (status%status_code /= IF_STATUS_OK) return
    
    ! Add hourglass force to residual
    if (allocated(state_out%Re)) then
      do i = 1, 8
        state_out%Re((i-1)*3+1:(i-1)*3+3) = state_out%Re((i-1)*3+1:(i-1)*3+3) + F_hg(i, :)
      end do
    end if
    
    ! Compute hourglass energy (for monitoring)
    call RT_Hourglass_ComputeEnergy(h_mode, Q_hg, E_hg, status)
    
  end subroutine Calc_C3D8R

  subroutine Calc_Continuum(ElemType, Formul, Ctx, state_in, &
                               matModels, state_out, flags)
    type(ElemType),       intent(in)    :: ElemType
    type(ElemFormul), intent(in)    :: Formul
    type(ElemCtx),    intent(in)    :: Ctx
    type(ElemState),         intent(in)    :: state_in
    type(UF_MaterialModel),  intent(in)    :: matModels(:)
    type(ElemState),         intent(inout) :: state_out
    type(ElemFlags),      intent(out)   :: flags

    ! Facade: Dispatch to 3D/2D structural continuum implementation (internal B-bar dispatch)
    if (ElemType%dim == 3) then
      call Calc_Continuum3D(ElemType, Formul, Ctx, state_in, matModels, state_out, flags)
    else
      call Calc_Continuum2D_elem(ElemType, Formul, Ctx, state_in, matModels, state_out, flags)
    end if

  end subroutine Calc_Continuum

  subroutine Calc_Continuum2D_UF(ElemType, Formul, Ctx, state_in, &
                                 matModels, state_out, flags)
    type(UF_ElemType),        intent(in)    :: ElemType
    type(UF_ElemFormul), intent(in)    :: Formul
    type(UF_ElemCtx),     intent(in)    :: Ctx
    type(ElemState),       intent(in)    :: state_in
    type(UF_MaterialModel),      intent(in)    :: matModels(:)
    type(ElemState),       intent(inout) :: state_out
    type(UF_ElemFlags),       intent(out)   :: flags

    logical :: use_bbar_effect

    if (ElemType%dim /= 2_i4) then
      ! Only expect 2D/AXI elements
    end if

    use_bbar_effect = Formul%use_bbar
    if (.not. use_bbar_effect) then
      if (Formul%integration_scheme == UF_Int_Selective) use_bbar_effect = .true.
    end if

    if (use_bbar_effect) then
      select case (ElemType%topo)
      case (UF_Topo_Quad)
        if (ElemType%pop%n_nodes == 4) then
          call Compute_Continuum_CPE4_BBar_Exact(Calc_Continuum_Base, ElemType, Formul, &
                                                 Ctx, state_in, matModels, state_out, flags)
          return
        else if (ElemType%pop%n_nodes == 8) then
          call Compute_Continuum_CPE8R_BBar_Exact(Calc_Continuum_Base, ElemType, Formul, &
                                                  Ctx, state_in, matModels, state_out, flags)
          return
        end if

      case (UF_Topo_Tri)
        if (ElemType%pop%n_nodes == 6) then
          call Compute_Continuum_CPE6_BBar_Exact(Calc_Continuum_Base, ElemType, Formul, &
                                                 Ctx, state_in, matModels, state_out, flags)
          return
        end if
      end select
    end if

    call Calc_Continuum_Base(ElemType, Formul, Ctx, state_in, matModels, state_out, flags)

  end subroutine Calc_Continuum2D_UF

  subroutine Calc_Continuum2D_elem(ElemType, Formul, Ctx, state_in, &
                                 matModels, state_out, flags)
    type(ElemType),       intent(in)    :: ElemType
    type(ElemFormul), intent(in)    :: Formul
    type(ElemCtx),    intent(in)    :: Ctx
    type(ElemState),         intent(in)    :: state_in
    type(UF_MaterialModel),  intent(in)    :: matModels(:)
    type(ElemState),         intent(inout) :: state_out
    type(ElemFlags),      intent(out)   :: flags

    logical :: use_bbar_effect
    integer(i4) :: nn_e

    if (ElemType%dim /= 2_i4) then
    end if

    ! Base ElemFormul: use_bbar + integration_scheme aligned with UF_ElemFormul
    use_bbar_effect = Formul%use_bbar
    if (.not. use_bbar_effect) then
      if (Formul%integration_scheme == UF_Int_Selective) use_bbar_effect = .true.
    end if

    nn_e = PH_Contm_NNodes_Base(ElemType)

    if (use_bbar_effect) then
      select case (ElemType%topo)
      case (UF_Topo_Quad)
        if (nn_e == 4) then
          call Compute_Continuum_CPE4_BBar_Exact(Calc_Continuum_Base, ElemType, Formul, &
                                                 Ctx, state_in, matModels, state_out, flags)
          return
        else if (nn_e == 8) then
          call Compute_Continuum_CPE8R_BBar_Exact(Calc_Continuum_Base, ElemType, Formul, &
                                                  Ctx, state_in, matModels, state_out, flags)
          return
        end if

      case (UF_Topo_Tri)
        if (nn_e == 6) then
          call Compute_Continuum_CPE6_BBar_Exact(Calc_Continuum_Base, ElemType, Formul, &
                                                 Ctx, state_in, matModels, state_out, flags)
          return
        end if
      end select
    end if

    call Calc_Continuum_Base(ElemType, Formul, Ctx, state_in, matModels, state_out, flags)

  end subroutine Calc_Continuum2D_elem

  subroutine Calc_Continuum2D_Thermal(ElemType, Formul, Ctx, state_in, &
                                         matModels, state_out, flags)
    type(ElemType),       intent(in)    :: ElemType
    type(ElemFormul), intent(in)    :: Formul
    type(ElemCtx),    intent(in)    :: Ctx
    type(ElemState),         intent(in)    :: state_in
    type(UF_MaterialModel),  intent(in)    :: matModels(:)
    type(ElemState),         intent(inout) :: state_out
    type(ElemFlags),      intent(out)   :: flags

    real(wp), pointer :: Ke(:,:), Re(:)
    real(wp), pointer :: Me(:,:), Ce(:,:)

    integer(i4) :: nNode, nDim
    integer(i4) :: ndpn_struct, ndpn_total
    integer(i4) :: nDOF_struct, nDOF_total
    integer(i4) :: iNode, jNode, a
    integer(i4) :: rowT, colT

    type(ElemType) :: elemType_struct

    integer(i4) :: ip, aDim
    logical     :: isAxisym, isPlaneStress
    real(wp), pointer     :: Ctt(:,:)
    real(wp), allocatable :: B(:,:), Buq(:)
    real(wp), allocatable :: T_new(:), T_old(:)
    real(wp) :: gradni_dot_grad
    real(wp) :: k_cond, rho, alphaT, c_p, dt
    real(wp) :: q(6)
    real(wp) :: E, nu
    real(wp) :: flag_th_exp
    real(wp) :: totalVol, L_char, alpha_th, stableDt_th
    type(MatProperties) :: props
    type(UF_ThermalPointState) :: thState
    integer(i4) :: ierr_material
    logical :: hasThermalField, hasTempIncr, hasthermoexpans, hasTransient
    logical :: enablethermoexp
    logical :: ignoreCapacity, effHasTransient
    type(ElemFormul) :: form_th

    nNode = PH_Contm_NNodes_Base(ElemType)
    nDim  = ElemType%dim

    if (nDim /= 2_i4) then
      flags%failed              = .true.
      flags%suggest_cutback     = .false.
      flags%requires_reasse = .false.
      flags%stableDt            = 0.0_wp
      call init_error_status(flags%status, IF_STATUS_INVALID, &
        message='Calc_Continuum2D_Thermal: expected ElemType%dim=2')
      state_out%failed   = flags%failed
      state_out%stableDt = flags%stableDt
      return
    end if

    ndpn_struct = 2
    ndpn_total  = 3
    nDOF_struct = nNode * ndpn_struct
    nDOF_total  = nNode * ndpn_total

    flags%failed              = .false.
    flags%suggest_cutback     = .false.
    flags%requires_reasse = .true.
    flags%stableDt            = 0.0_wp

    call RT_Elem_WS_GetMultiField(nDOF_total, Ke, Re, Me, Ce)

    elemType_struct = ElemType
    elemType_struct%n_dof_per_node = ndpn_struct

    call Calc_Continuum(elemType_struct, Formul, Ctx, state_in, &
                           matModels, state_out, flags)

    call UF_Embed_StructBlock(nNode, ndpn_struct, ndpn_total, &
                              Ke, Re, Me, Ce, &
                              state_out%evo%Ke(1:nDOF_struct, 1:nDOF_struct), &
                              state_out%Re(1:nDOF_struct), &
                              state_out%Me(1:nDOF_struct, 1:nDOF_struct), &
                              state_out%Ce(1:nDOF_struct, 1:nDOF_struct))

    props  = matModels(1)%props
    E      = 0.0_wp
    nu     = 0.0_wp
    if (allocated(props%props)) then
      if (size(props%props) >= 1) E  = props%props(1)
      if (size(props%props) >= 2) nu = props%props(2)
    end if

    call ThermCoeffs(matModels(1), Ctx, k_cond, rho, c_p, &
                       alphaT, flag_th_exp, hasTransient, thState, ierr_material)

    dt          = max(Ctx%dTime, 0.0_wp)
    totalVol    = 0.0_wp
    stableDt_th = 0.0_wp

    hasThermalField  = allocated(Ctx%temp)
    hasTempIncr      = allocated(Ctx%temp_incr)

    ignoreCapacity   = Ctx%ignoreCapacity
    effHasTransient  = hasTransient .and. .not. ignoreCapacity

    enablethermoexp = (flag_th_exp > 0.5_wp)
    hasthermoexpans = (enablethermoexp .and. &
                          alphaT /= 0.0_wp .and. E > 0.0_wp .and. hasThermalField)

    if (hasthermoexpans) then
      allocate(B(6, nDOF_struct))
      allocate(Buq(nDOF_struct))
    end if

    if (effHasTransient) then
      call ThermAllocCtt(nNode, Ctt)
    else
      Ctt => null()
    end if

    isAxisym      = (index(ElemType%name, 'CAX') > 0)
    isPlaneStress = (.not. isAxisym .and. index(ElemType%name, 'CPS') > 0)

    form_th = Formul
    form_th%kineFormulation = UF_Form_TL

    q = 0.0_wp
    if (hasthermoexpans) then
      real(wp) :: lambda, mu
      real(wp) :: Dloc(6,6)
      integer(i4) :: ii, jj

      Dloc = 0.0_wp
      lambda = E*nu / max((1.0_wp+nu)*(1.0_wp-2.0_wp*nu), 1.0e-12_wp)
      mu     = E / max(2.0_wp*(1.0_wp+nu), 1.0e-12_wp)

      Dloc(1,1) = lambda + 2.0_wp*mu
      Dloc(2,2) = Dloc(1,1)
      Dloc(3,3) = Dloc(1,1)
      Dloc(1,2) = lambda
      Dloc(1,3) = lambda
      Dloc(2,1) = lambda
      Dloc(2,3) = lambda
      Dloc(3,1) = lambda
      Dloc(3,2) = lambda
      Dloc(4,4) = mu
      Dloc(5,5) = mu
      Dloc(6,6) = mu

      do ii = 1, 6
        do jj = 1, 3
          q(ii) = q(ii) + Dloc(ii, jj)
        end do
        q(ii) = alphaT * q(ii)
      end do
    end if

    call ContGauss(ElemType, form_th, Ctx, Therm_IpKernel)

    if (allocated(B))   deallocate(B)
    if (allocated(Buq)) deallocate(Buq)

    if (hasThermalField) then
      if (size(Ctx%temp) >= nNode) then
        do iNode = 1, nNode
          rowT = (iNode-1)*ndpn_total + ndpn_total
          if (rowT < 1 .or. rowT > size(Re)) cycle
          do jNode = 1, nNode
            colT = (jNode-1)*ndpn_total + ndpn_total
            if (colT < 1 .or. colT > size(Ke,2)) cycle
            Re(rowT) = Re(rowT) + Ke(rowT, colT) * Ctx%temp(jNode)
          end do
        end do
      end if
    end if

    if (effHasTransient) then
      allocate(T_new(nNode), T_old(nNode))
      do jNode = 1, nNode
        if (jNode <= size(Ctx%temp)) then
          T_new(jNode) = Ctx%temp(jNode)
        else
          T_new(jNode) = 0.0_wp
        end if
        if (jNode <= size(Ctx%temp_incr)) then
          T_old(jNode) = T_new(jNode) - Ctx%temp_incr(jNode)
        else
          T_old(jNode) = T_new(jNode)
        end if
      end do

      do iNode = 1, nNode
        rowT = (iNode-1)*ndpn_total + ndpn_total
        if (rowT < 1 .or. rowT > size(Re)) cycle
        do jNode = 1, nNode
          colT = (jNode-1)*ndpn_total + ndpn_total
          if (colT < 1 .or. colT > size(Ke,2)) cycle
          Ke(rowT, colT) = Ke(rowT, colT) + Ctt(iNode, jNode) / dt
          Re(rowT)       = Re(rowT)       + (Ctt(iNode, jNode) / dt) * &
                                         (T_new(jNode) - T_old(jNode))
        end do
      end do

      deallocate(T_new, T_old)
    end if

    if (totalVol > 0.0_wp .and. nDim > 0) then
      L_char = totalVol ** (1.0_wp / real(nDim, wp))
      if (hasTransient .and. k_cond > 0.0_wp .and. rho > 0.0_wp .and. c_p > 0.0_wp) then
        alpha_th    = k_cond / max(rho * c_p, 1.0e-16_wp)
        stableDt_th = 0.5_wp * L_char*L_char / max(alpha_th, 1.0e-16_wp)
      end if
    end if

    call UF_Element_CombineStableDt(stableDt_th, Ctx%dTime, flags)

    state_out%evo%Ke(1:nDOF_total,1:nDOF_total) = Ke(1:nDOF_total,1:nDOF_total)
    state_out%Re(1:nDOF_total)             = Re(1:nDOF_total)
    state_out%Me(1:nDOF_total,1:nDOF_total) = Me(1:nDOF_total,1:nDOF_total)
    state_out%Ce(1:nDOF_total,1:nDOF_total) = Ce(1:nDOF_total,1:nDOF_total)

    state_out%failed   = flags%failed
    state_out%stableDt = flags%stableDt

  contains

    subroutine Therm_IpKernel(ip, sf, dN_dx_ip, dVol_ip, radius_ip)
      integer(i4), intent(in) :: ip
      type(ShapeFuncResult), intent(in) :: sf
      real(wp), intent(in) :: dN_dx_ip(:,:)
      real(wp), intent(in) :: dVol_ip, radius_ip

      integer(i4) :: iNode, jNode, aDim, a
      integer(i4) :: rowT, colT, row_u, row_full
      real(wp) :: DeltaT_ip
      real(wp) :: dNx, dNy
      integer(i4) :: col

      totalVol = totalVol + dVol_ip

      if (k_cond > 0.0_wp) then
        do iNode = 1, nNode
          rowT = (iNode-1)*ndpn_total + ndpn_total
          do jNode = 1, nNode
            colT = (jNode-1)*ndpn_total + ndpn_total
            gradni_dot_grad = 0.0_wp
            do aDim = 1, nDim
              gradni_dot_grad = gradni_dot_grad + dN_dx_ip(iNode, aDim) * dN_dx_ip(jNode, aDim)
            end do
            Ke(rowT, colT) = Ke(rowT, colT) + k_cond * gradni_dot_grad * dVol_ip
          end do
        end do
      end if

      if (hasthermoexpans) then
        B = 0.0_wp
        do iNode = 1, nNode
          dNx = dN_dx_ip(iNode,1)
          dNy = dN_dx_ip(iNode,2)
          col = (iNode-1)*ndpn_struct
          B(1, col+1) = dNx
          B(2, col+2) = dNy
          B(4, col+1) = dNy
          B(4, col+2) = dNx
          if (isAxisym) then
            if (radius_ip > 1.0e-12_wp) then
              B(3, col+1) = sf%N(iNode, 1) / radius_ip
            else
              B(3, col+1) = sf%N(iNode, 1) / 1.0e-12_wp
            end if
          end if
        end do

        Buq = 0.0_wp
        Buq(1:nDOF_struct) = matmul(transpose(B(1:6,1:nDOF_struct)), q(1:6))

        DeltaT_ip = 0.0_wp
        if (hasThermalField) then
          do jNode = 1, nNode
            if (jNode <= size(Ctx%temp)) then
              DeltaT_ip = DeltaT_ip + sf%N(jNode, 1) * Ctx%temp(jNode)
            end if
          end do
        end if

        do iNode = 1, nNode
          do a = 1, ndpn_struct
            row_u    = (iNode-1)*ndpn_struct + a
            row_full = (iNode-1)*ndpn_total  + a
            if (row_full >= 1 .and. row_full <= size(Re)) then
              Re(row_full) = Re(row_full) + Buq(row_u) * DeltaT_ip * dVol_ip
            end if
          end do
        end do

        do jNode = 1, nNode
          colT = (jNode-1)*ndpn_total + ndpn_total
          if (colT < 1 .or. colT > size(Ke,2)) cycle
          do iNode = 1, nNode
            do a = 1, ndpn_struct
              row_u    = (iNode-1)*ndpn_struct + a
              row_full = (iNode-1)*ndpn_total  + a
              if (row_full < 1 .or. row_full > size(Ke,1)) cycle
              Ke(row_full, colT) = Ke(row_full, colT) + Buq(row_u) * sf%N(jNode, 1) * dVol_ip
            end do
          end do
        end do
      end if

      if (hasTransient) then
        real(wp) :: Nij
        do iNode = 1, nNode
          do jNode = 1, nNode
            Nij = sf%N(iNode, 1) * sf%N(jNode, 1)
            Ctt(iNode, jNode) = Ctt(iNode, jNode) + rho * c_p * Nij * dVol_ip
          end do
        end do
      end if

    end subroutine Therm_IpKernel

  end subroutine Calc_Continuum2D_Thermal


  subroutine Calc_Continuum2D_THM(ElemType, Formul, Ctx, state_in, &
                                     matModels, state_out, flags)
    type(ElemType),       intent(in)    :: ElemType
    type(ElemFormul), intent(in)    :: Formul
    type(ElemCtx),    intent(in)    :: Ctx
    type(ElemState),         intent(in)    :: state_in
    type(UF_MaterialModel),  intent(in)    :: matModels(:)
    type(ElemState),         intent(inout) :: state_out
    type(ElemFlags),      intent(out)   :: flags

    real(wp), pointer :: Ke(:,:), Re(:)
    real(wp), pointer :: Me(:,:), Ce(:,:)

    integer(i4) :: nNode, nDim
    integer(i4) :: ndpn_struct, ndpn_total
    integer(i4) :: nDOF_struct, nDOF_total
    integer(i4) :: iNode, jNode, kNode, a, b
    integer(i4) :: row_u, col_u, row_full, col_full
    integer(i4) :: idxT, idxP

    type(ElemType) :: elemType_struct

    integer(i4) :: ip, aDim
    logical     :: isAxisym
    real(wp), allocatable :: Ctt(:,:)
    real(wp), allocatable :: Spp(:,:)
    real(wp), pointer     :: B(:,:), mB(:)

    real(wp) :: k_th, rho_s, c_p_s, rho_f, c_p_f, rhoCp, dt
    real(wp) :: alpha_b, k_hyd, S_s
    real(wp) :: m_vec(6)
    real(wp) :: volRate_ip, u_dot_loc
    real(wp) :: flag_vol
    real(wp) :: gradni_dot_grad
    real(wp) :: Nij
    real(wp) :: grad_p(3), v_darcy(3), v_dot_gradNi, v_dot_gradni_dp, T_ip, p_j
    real(wp) :: p_ip
    real(wp) :: totalVol, L_char, alpha_heat, alpha_poro, stableDt_heat, stableDt_poro

    type(MatProperties) :: props
    type(UF_THMPointState) :: thmState

    integer(i4) :: rowT, colT, rowP, colP
    integer(i4) :: ierr_material
    logical :: hasTempField, hasTempIncr
    logical :: hasPoreField, hasPoreIncr
    logical :: hasTransient_T, hasTransient_P, hasBiotCoupling
    logical :: ignoreCapacity, effhastransient, effhastransient
    logical :: volrate_materia, volRate_on

    nNode = PH_Contm_NNodes_Base(ElemType)
    nDim  = ElemType%dim

    if (nDim /= 2_i4) then
      flags%failed              = .true.
      flags%suggest_cutback     = .false.
      flags%requires_reasse = .false.
      flags%stableDt            = 0.0_wp
      call init_error_status(flags%status, IF_STATUS_INVALID, &
        message='Calc_Continuum2D_THM: expected ElemType%dim=2')
      state_out%failed   = flags%failed
      state_out%stableDt = flags%stableDt
      return
    end if

    ndpn_struct = 2
    ndpn_total  = ndpn_struct + 2
    idxT        = ndpn_struct + 1
    idxP        = ndpn_struct + 2

    nDOF_struct = nNode * ndpn_struct
    nDOF_total  = nNode * ndpn_total

    flags%failed              = .false.
    flags%suggest_cutback     = .false.
    flags%requires_reasse = .true.
    flags%stableDt            = 0.0_wp

    call RT_Elem_WS_GetMultiField(nDOF_total, Ke, Re, Me, Ce)

    elemType_struct = ElemType
    elemType_struct%n_dof_per_node = ndpn_struct

    call Calc_Continuum(elemType_struct, Formul, Ctx, state_in, &
                           matModels, state_out, flags)

    call UF_Embed_StructBlock(nNode, ndpn_struct, ndpn_total, &
                              Ke, Re, Me, Ce, &
                              state_out%evo%Ke(1:nDOF_struct, 1:nDOF_struct), &
                              state_out%Re(1:nDOF_struct), &
                              state_out%Me(1:nDOF_struct, 1:nDOF_struct), &
                              state_out%Ce(1:nDOF_struct, 1:nDOF_struct))

    props  = matModels(1)%props

    thmState%mech%cfg%id    = matModels(1)%cfg%id
    thmState%thermal%cfg%id = matModels(1)%cfg%id
    thmState%poro%cfg%id    = matModels(1)%cfg%id

    thmState%mech%time     = Ctx%time_curr
    thmState%thermal%time  = Ctx%time_curr
    thmState%poro%time     = Ctx%time_curr

    thmState%mech%dtime    = Ctx%dTime
    thmState%thermal%dtime = Ctx%dTime
    thmState%poro%dtime    = Ctx%dTime

    call THMCoeffs(matModels(1), thmState, rho_s, k_th, c_p_s, &
                   rho_f, c_p_f, alpha_b, k_hyd, S_s, flag_vol, ierr_material)

    dt = max(Ctx%dTime, 0.0_wp)
    totalVol      = 0.0_wp
    stableDt_heat = 0.0_wp
    stableDt_poro = 0.0_wp

    hasTempField  = allocated(Ctx%temp)
    hasTempIncr   = allocated(Ctx%temp_incr)
    hasPoreField  = allocated(Ctx%pore)
    hasPoreIncr   = allocated(Ctx%pore_incr)

    rhoCp = rho_s * c_p_s + rho_f * c_p_f

    hasTransient_T   = (rhoCp > 0.0_wp .and. dt > 0.0_wp .and. hasTempField .and. hasTempIncr)
    hasBiotCoupling  = (alpha_b /= 0.0_wp)
    hasTransient_P   = (S_s > 0.0_wp .and. dt > 0.0_wp .and. hasPoreField .and. hasPoreIncr)

    ignoreCapacity     = Ctx%ignoreCapacity
    effhastransient  = hasTransient_T .and. .not. ignoreCapacity
    effhastransient  = hasTransient_P .and. .not. ignoreCapacity

    volrate_materia = (flag_vol > 0.5_wp)
    volRate_on  = (ENABLE_VOLRATE_COUPLING_DEFAULT .and. volrate_materia)

    if (effhastransient) then
      call THMAllocCtt(nNode, Ctt)
    end if

    if (effhastransient) then
      call THMAllocSpp(nNode, Spp)
    end if

    if (hasBiotCoupling) then
      call RT_Elem_WS_GetStructBm_2(nDOF_struct, B, mB)
      m_vec = 0.0_wp
      m_vec(1) = 1.0_wp
      m_vec(2) = 1.0_wp
      m_vec(3) = 1.0_wp
    end if

    isAxisym = (index(ElemType%name, 'CAX') > 0)

    call ContGauss(ElemType, Formul, Ctx, THM2D_IpKernel)

    if (totalVol > 0.0_wp .and. nDim > 0) then
      L_char = totalVol ** (1.0_wp / real(nDim, wp))

      if (hasTransient_T .and. k_th > 0.0_wp .and. rhoCp > 0.0_wp) then
        alpha_heat    = k_th / max(rhoCp, 1.0e-16_wp)
        stableDt_heat = 0.5_wp * L_char*L_char / max(alpha_heat, 1.0e-16_wp)
      end if

      if (hasTransient_P .and. k_hyd > 0.0_wp .and. S_s > 0.0_wp) then
        alpha_poro    = k_hyd / max(S_s, 1.0e-16_wp)
        stableDt_poro = 0.5_wp * L_char*L_char / max(alpha_poro, 1.0e-16_wp)
      end if
    end if

    call UF_Element_CombineStableDt(stableDt_heat, Ctx%dTime, flags)
    call UF_Element_CombineStableDt(stableDt_poro, Ctx%dTime, flags)

    if (hasTempField) then
      if (size(Ctx%temp) >= nNode) then
        do iNode = 1, nNode
          rowT = (iNode-1)*ndpn_total + idxT
          if (rowT < 1 .or. rowT > size(Re)) cycle
          do jNode = 1, nNode
            colT = (jNode-1)*ndpn_total + idxT
            if (colT < 1 .or. colT > size(Ke,2)) cycle
            Re(rowT) = Re(rowT) + Ke(rowT, colT) * Ctx%temp(jNode)
          end do
        end do
      end if
    end if

    if (effhastransient .and. allocated(Ctt)) then
      do iNode = 1, nNode
        rowT = (iNode-1)*ndpn_total + idxT
        if (rowT < 1 .or. rowT > size(Re)) cycle
        do jNode = 1, nNode
          colT = (jNode-1)*ndpn_total + idxT
          if (colT < 1 .or. colT > size(Ke,2)) cycle
          Ke(rowT, colT) = Ke(rowT, colT) + Ctt(iNode, jNode) / dt
          if (jNode <= size(Ctx%temp_incr)) then
            Re(rowT) = Re(rowT) + (Ctt(iNode, jNode) / dt) * Ctx%temp_incr(jNode)
          end if
        end do
      end do
    end if

    if (hasPoreField) then
      if (size(Ctx%pore) >= nNode) then
        do iNode = 1, nNode
          rowP = (iNode-1)*ndpn_total + idxP
          if (rowP < 1 .or. rowP > size(Re)) cycle
          do jNode = 1, nNode
            colP = (jNode-1)*ndpn_total + idxP
            if (colP < 1 .or. colP > size(Ke,2)) cycle
            Re(rowP) = Re(rowP) + Ke(rowP, colP) * Ctx%pore(jNode)
          end do
        end do
      end if
    end if

    if (effhastransient .and. allocated(Spp)) then
      do iNode = 1, nNode
        rowP = (iNode-1)*ndpn_total + idxP
        if (rowP < 1 .or. rowP > size(Re)) cycle
        do jNode = 1, nNode
          colP = (jNode-1)*ndpn_total + idxP
          if (colP < 1 .or. colP > size(Ke,2)) cycle
          Ke(rowP, colP) = Ke(rowP, colP) + Spp(iNode, jNode) / dt
          if (jNode <= size(Ctx%pore_incr)) then
            Re(rowP) = Re(rowP) + (Spp(iNode, jNode) / dt) * Ctx%pore_incr(jNode)
          end if
        end do
      end do
    end if

    state_out%evo%Ke(1:nDOF_total,1:nDOF_total) = Ke(1:nDOF_total,1:nDOF_total)
    state_out%Re(1:nDOF_total)             = Re(1:nDOF_total)
    state_out%Me(1:nDOF_total,1:nDOF_total) = Me(1:nDOF_total,1:nDOF_total)
    state_out%Ce(1:nDOF_total,1:nDOF_total) = Ce(1:nDOF_total,1:nDOF_total)

    state_out%failed   = flags%failed
    state_out%stableDt = flags%stableDt

  contains

    subroutine THM2D_IpKernel(ip, sf, dN_dx_ip, dVol_ip, radius_ip)
      integer(i4), intent(in) :: ip
      type(ShapeFuncResult), intent(in) :: sf
      real(wp), intent(in) :: dN_dx_ip(:,:)
      real(wp), intent(in) :: dVol_ip, radius_ip

      integer(i4) :: iNode, jNode, aDim, col
      integer(i4) :: rowT, colT, rowP, colP, row_full
      real(wp)    :: dNx, dNy
      real(wp)    :: v_dot_gradNi, v_dot_gradni_dp
      real(wp)    :: volRate_loc

      totalVol = totalVol + dVol_ip

      if (k_th > 0.0_wp) then
        do iNode = 1, nNode
          rowT = (iNode-1)*ndpn_total + idxT
          do jNode = 1, nNode
            colT = (jNode-1)*ndpn_total + idxT

            gradni_dot_grad = 0.0_wp
            do aDim = 1, nDim
              gradni_dot_grad = gradni_dot_grad + dN_dx_ip(iNode, aDim) * dN_dx_ip(jNode, aDim)
            end do

            Ke(rowT, colT) = Ke(rowT, colT) + k_th * gradni_dot_grad * dVol_ip

          end do
        end do
      end if

      if (hasTransient_T .and. effhastransient) then
        do iNode = 1, nNode
          do jNode = 1, nNode
            Nij = sf%N(iNode, 1) * sf%N(jNode, 1)
            Ctt(iNode, jNode) = Ctt(iNode, jNode) + rhoCp * Nij * dVol_ip
          end do
        end do
      end if

      if (k_hyd > 0.0_wp) then
        do iNode = 1, nNode
          rowP = (iNode-1)*ndpn_total + idxP
          do jNode = 1, nNode
            colP = (jNode-1)*ndpn_total + idxP

            gradni_dot_grad = 0.0_wp
            do aDim = 1, nDim
              gradni_dot_grad = gradni_dot_grad + dN_dx_ip(iNode, aDim) * dN_dx_ip(jNode, aDim)
            end do

            Ke(rowP, colP) = Ke(rowP, colP) + k_hyd * gradni_dot_grad * dVol_ip
          end do
        end do
      end if

      if (rho_f > 0.0_wp .and. c_p_f > 0.0_wp .and. k_hyd > 0.0_wp &
          .and. hasTempField .and. hasPoreField) then

        grad_p = 0.0_wp
        do jNode = 1, nNode
          if (jNode <= size(Ctx%pore)) then
            p_j = Ctx%pore(jNode)
          else
            p_j = 0.0_wp
          end if
          do aDim = 1, nDim
            grad_p(aDim) = grad_p(aDim) + dN_dx_ip(jNode, aDim) * p_j
          end do
        end do

        v_darcy = 0.0_wp
        do aDim = 1, nDim
          v_darcy(aDim) = -k_hyd * grad_p(aDim)
        end do

        T_ip = 0.0_wp
        do jNode = 1, nNode
          if (jNode <= size(Ctx%temp)) then
            T_ip = T_ip + sf%N(jNode, 1) * Ctx%temp(jNode)
          end if
        end do

        do iNode = 1, nNode
          rowT = (iNode-1)*ndpn_total + idxT
          if (rowT < 1 .or. rowT > size(Re)) cycle

          v_dot_gradNi = 0.0_wp
          do aDim = 1, nDim
            v_dot_gradNi = v_dot_gradNi + v_darcy(aDim) * dN_dx_ip(iNode, aDim)
          end do

          Re(rowT) = Re(rowT) + rho_f * c_p_f * v_dot_gradNi * T_ip * dVol_ip
        end do

        do iNode = 1, nNode
          rowT = (iNode-1)*ndpn_total + idxT
          if (rowT < 1 .or. rowT > size(Ke,1)) cycle

          v_dot_gradNi = 0.0_wp
          do aDim = 1, nDim
            v_dot_gradNi = v_dot_gradNi + v_darcy(aDim) * dN_dx_ip(iNode, aDim)
          end do

          do jNode = 1, nNode
            colT = (jNode-1)*ndpn_total + idxT
            if (colT < 1 .or. colT > size(Ke,2)) cycle
            Ke(rowT, colT) = Ke(rowT, colT) + rho_f * c_p_f * v_dot_gradNi * sf%N(jNode, 1) * dVol_ip
          end do
        end do

        do kNode = 1, nNode
          colP = (kNode-1)*ndpn_total + idxP
          if (colP < 1 .or. colP > size(Ke,2)) cycle

          do iNode = 1, nNode
            rowT = (iNode-1)*ndpn_total + idxT
            if (rowT < 1 .or. rowT > size(Ke,1)) cycle

            v_dot_gradni_dp = 0.0_wp
            do aDim = 1, nDim
              v_dot_gradni_dp = v_dot_gradni_dp - k_hyd * dN_dx_ip(kNode, aDim) * dN_dx_ip(iNode, aDim)
            end do

            Ke(rowT, colP) = Ke(rowT, colP) + rho_f * c_p_f * v_dot_gradni_dp * T_ip * dVol_ip
          end do
        end do

      end if

      if (hasBiotCoupling .and. hasPoreField) then
        B = 0.0_wp
        do iNode = 1, nNode
          dNx = dN_dx_ip(iNode,1)
          dNy = dN_dx_ip(iNode,2)
          col = (iNode-1)*ndpn_struct
          B(1, col+1) = dNx
          B(2, col+2) = dNy
          B(4, col+1) = dNy
          B(4, col+2) = dNx
          if (isAxisym) then
            if (radius_ip > 1.0e-12_wp) then
              B(3, col+1) = sf%N(iNode, 1) / radius_ip
            else
              B(3, col+1) = sf%N(iNode, 1) / 1.0e-12_wp
            end if
          end if
        end do

        mB = 0.0_wp
        mB(1:nDOF_struct) = matmul(transpose(B(1:6,1:nDOF_struct)), m_vec(1:6))

        p_ip = 0.0_wp
        if (size(Ctx%pore) >= nNode) then
          do jNode = 1, nNode
            p_ip = p_ip + sf%N(jNode, 1) * Ctx%pore(jNode)
          end do
        end if

        do iNode = 1, nNode
          do a = 1, ndpn_struct
            row_u    = (iNode-1)*ndpn_struct + a
            row_full = (iNode-1)*ndpn_total  + a
            if (row_full >= 1 .and. row_full <= size(Re)) then
              Re(row_full) = Re(row_full) - alpha_b * mB(row_u) * p_ip * dVol_ip
            end if
          end do
        end do

        do jNode = 1, nNode
          colP = (jNode-1)*ndpn_total + idxP
          if (colP < 1 .or. colP > size(Ke,2)) cycle
          do iNode = 1, nNode
            do a = 1, ndpn_struct
              row_u    = (iNode-1)*ndpn_struct + a
              row_full = (iNode-1)*ndpn_total  + a
              if (row_full < 1 .or. row_full > size(Ke,1)) cycle
              Ke(row_full, colP) = Ke(row_full, colP) - alpha_b * mB(row_u) * sf%N(jNode, 1) * dVol_ip
            end do
          end do
        end do
      end if

      if (effhastransient) then
        do iNode = 1, nNode
          do jNode = 1, nNode
            Nij = sf%N(iNode, 1) * sf%N(jNode, 1)
            Spp(iNode, jNode) = Spp(iNode, jNode) + S_s * Nij * dVol_ip
          end do
        end do
      end if

      if (hasTransient_P .and. hasBiotCoupling .and. volRate_on) then

        volRate_loc = 0.0_wp
        if (dt > 0.0_wp) then
          do iNode = 1, nNode
            do a = 1, ndpn_struct
              row_u = (iNode-1)*ndpn_struct + a
              if (a <= size(Ctx%disp_incr,1) .and. iNode <= size(Ctx%disp_incr,2)) then
                u_dot_loc = Ctx%disp_incr(a, iNode) / dt
              else
                u_dot_loc = 0.0_wp
              end if
              volRate_loc = volRate_loc + mB(row_u) * u_dot_loc
            end do
          end do
        end if

        if (abs(volRate_loc) > 0.0_wp) then
          do iNode = 1, nNode
            rowP = (iNode-1)*ndpn_total + idxP
            if (rowP < 1 .or. rowP > size(Re)) cycle
            Re(rowP) = Re(rowP) + alpha_b * volRate_loc * sf%N(iNode, 1) * dVol_ip
          end do

          if (dt > 0.0_wp) then
            do iNode = 1, nNode
              rowP = (iNode-1)*ndpn_total + idxP
              if (rowP < 1 .or. rowP > size(Ke,1)) cycle
              do jNode = 1, nNode
                do a = 1, ndpn_struct
                  col_u    = (jNode-1)*ndpn_struct + a
                  col_full = (jNode-1)*ndpn_total  + a
                  if (col_full < 1 .or. col_full > size(Ke,2)) cycle
                  Ke(rowP, col_full) = Ke(rowP, col_full) + alpha_b * sf%N(iNode, 1) * mB(col_u) * dVol_ip / dt
                end do
              end do
            end do
          end if
        end if
      end if

    end subroutine THM2D_IpKernel

  end subroutine Calc_Continuum2D_THM

  SUBROUTINE Calc_Continuum3D(ElemType, Formul, Ctx, state_in, &
                                 matModels, state_out, flags)
    TYPE(UF_ElemType), INTENT(IN) :: ElemType
    TYPE(UF_ElemFormul), INTENT(IN) :: Formul
    TYPE(UF_ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(UF_MaterialModel), INTENT(IN) :: matModels(:)
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(UF_ElemFlags), INTENT(OUT) :: flags

    TYPE(PH_Elem_Contm_Calc3D_Arg) :: in_struct
    
    in_struct%elem_type = ElemType
    in_struct%formul = Formul
    in_struct%ctx = Ctx
    in_struct%state_in = state_in
    ALLOCATE(in_struct%mat_models(SIZE(matModels)))
    in_struct%mat_models = matModels
    
    CALL PH_Elem_Contm_Calc3D(in_struct)
    
    state_out = in_struct%state_out
    flags = in_struct%flags
    
    IF (ALLOCATED(in_struct%mat_models)) DEALLOCATE(in_struct%mat_models)

  END SUBROUTINE Calc_Continuum3D

  subroutine Calc_Continuum3D_Reduced(ElemType, Formul, Ctx, state_in, &
                                         matModels, state_out, flags)
    !! Dispatch to appropriate reduced integration element
    
    type(UF_ElemType),        intent(in)    :: ElemType
    type(UF_ElemFormul), intent(in)    :: Formul
    type(UF_ElemCtx),     intent(in)    :: Ctx
    type(ElemState),       intent(in)    :: state_in
    type(UF_MaterialModel),      intent(in)    :: matModels(:)
    type(ElemState),       intent(inout) :: state_out
    type(UF_ElemFlags),       intent(out)   :: flags
    
    select case (trim(ElemType%name))
    case ('C3D8R')
      call Calc_C3D8R(ElemType, Formul, Ctx, state_in, &
                         matModels, state_out, flags)
    case ('C3D20R')
      call Calc_C3D20R(ElemType, Formul, Ctx, state_in, &
                          matModels, state_out, flags)
    case default
      ! Fallback to base computation
      call Calc_Continuum3D(ElemType, Formul, Ctx, state_in, &
                               matModels, state_out, flags)
    end select
    
  end subroutine Calc_Continuum3D_Reduced

  subroutine Calc_Continuum3D_Thermal(ElemType, Formul, Ctx, state_in, &
                                         matModels, state_out, flags)
    type(UF_ElemType),        intent(in)    :: ElemType
    type(UF_ElemFormul), intent(in)    :: Formul
    type(UF_ElemCtx),     intent(in)    :: Ctx
    type(ElemState),       intent(in)    :: state_in
    type(UF_MaterialModel),      intent(in)    :: matModels(:)
    type(ElemState),       intent(inout) :: state_out
    type(UF_ElemFlags),       intent(out)   :: flags

    real(wp), pointer :: Ke(:,:), Re(:)
    real(wp), pointer :: Me(:,:), Ce(:,:)

    integer(i4) :: nNode, nDim
    integer(i4) :: ndpn_struct, ndpn_total
    integer(i4) :: nDOF_struct, nDOF_total
    integer(i4) :: iNode, jNode, a
    integer(i4) :: rowT, colT

    type(UF_ElemType) :: elemType_struct

    integer(i4) :: ip, aDim
    logical     :: isAxisym, isPlaneStress
    real(wp), pointer     :: Ctt(:,:)
    real(wp), allocatable :: B(:,:), Buq(:)
    real(wp), allocatable :: T_new(:), T_old(:)
    real(wp) :: gradni_dot_grad
    real(wp) :: k_cond, rho, alphaT, c_p, dt
    real(wp) :: q(6)
    real(wp) :: E, nu
    real(wp) :: flag_th_exp
    real(wp) :: totalVol, L_char, alpha_th, stableDt_th
    type(MatProperties) :: props
    type(UF_ThermalPointState) :: thState
    integer(i4) :: ierr_material
    logical :: hasThermalField, hasTempIncr, hasthermoexpans, hasTransient
    logical :: enablethermoexp
    logical :: ignoreCapacity, effHasTransient
    type(ElemFormul) :: fm_base
    type(ElemType) :: et_b
    type(ElemCtx) :: cx_b
    type(ElemFlags) :: fl_b

    nNode = ElemType%pop%n_nodes
    nDim  = ElemType%dim

    if (nDim /= 3_i4) then
      flags%failed              = .true.
      flags%suggest_cutback     = .false.
      flags%requires_reasse = .false.
      flags%stableDt            = 0.0_wp
      call init_error_status(flags%status, IF_STATUS_INVALID, &
        message='Calc_Continuum3D_Thermal: expected ElemType%dim=3')
      state_out%failed   = flags%failed
      state_out%stableDt = flags%stableDt
      return
    end if

    ndpn_struct = 3
    ndpn_total  = 4
    nDOF_struct = nNode * ndpn_struct
    nDOF_total  = nNode * ndpn_total

    flags%failed              = .false.
    flags%suggest_cutback     = .false.
    flags%requires_reasse = .true.
    flags%stableDt            = 0.0_wp

    call RT_Elem_WS_GetMultiField(nDOF_total, Ke, Re, Me, Ce)

    elemType_struct = ElemType
    elemType_struct%n_dof_per_node = ndpn_struct

    et_b = elemType_struct
    cx_b = Ctx
    call PH_Contm_UF_Formul_to_ElemFormul(Formul, fm_base)
    call Calc_Continuum(et_b, fm_base, cx_b, state_in, &
                           matModels, state_out, fl_b)
    flags = fl_b

    call UF_Embed_StructBlock(nNode, ndpn_struct, ndpn_total, &
                              Ke, Re, Me, Ce, &
                              state_out%evo%Ke(1:nDOF_struct, 1:nDOF_struct), &
                              state_out%Re(1:nDOF_struct), &
                              state_out%Me(1:nDOF_struct, 1:nDOF_struct), &
                              state_out%Ce(1:nDOF_struct, 1:nDOF_struct))

    props  = matModels(1)%props
    E      = 0.0_wp
    nu     = 0.0_wp
    if (allocated(props%props)) then
      if (size(props%props) >= 1) E  = props%props(1)
      if (size(props%props) >= 2) nu = props%props(2)
    end if

    call ThermCoeffs(matModels(1), Ctx, k_cond, rho, c_p, &
                       alphaT, flag_th_exp, hasTransient, thState, ierr_material)

    dt          = max(Ctx%dTime, 0.0_wp)
    totalVol    = 0.0_wp
    stableDt_th = 0.0_wp

    hasThermalField  = allocated(Ctx%temp)
    hasTempIncr      = allocated(Ctx%temp_incr)

    ignoreCapacity   = Ctx%ignoreCapacity
    effHasTransient  = hasTransient .and. .not. ignoreCapacity

    enablethermoexp = (flag_th_exp > 0.5_wp)
    hasthermoexpans = (enablethermoexp .and. &
                          alphaT /= 0.0_wp .and. E > 0.0_wp .and. hasThermalField)

    if (hasthermoexpans) then
      allocate(B(6, nDOF_struct))
      allocate(Buq(nDOF_struct))
    end if

    if (effHasTransient) then
      call ThermAllocCtt(nNode, Ctt)
    else
      Ctt => null()
    end if

    isAxisym     = .false.
    isPlaneStress = .false.

    fm_base%kineFormulation = UF_Form_TL

    q = 0.0_wp
    if (hasthermoexpans) then
      real(wp) :: lambda, mu
      real(wp) :: Dloc(6,6)
      integer(i4) :: ii, jj

      Dloc = 0.0_wp
      lambda = E*nu / max((1.0_wp+nu)*(1.0_wp-2.0_wp*nu), 1.0e-12_wp)
      mu     = E / max(2.0_wp*(1.0_wp+nu), 1.0e-12_wp)

      Dloc(1,1) = lambda + 2.0_wp*mu
      Dloc(2,2) = Dloc(1,1)
      Dloc(3,3) = Dloc(1,1)
      Dloc(1,2) = lambda
      Dloc(1,3) = lambda
      Dloc(2,1) = lambda
      Dloc(2,3) = lambda
      Dloc(3,1) = lambda
      Dloc(3,2) = lambda
      Dloc(4,4) = mu
      Dloc(5,5) = mu
      Dloc(6,6) = mu

      do ii = 1, 6
        do jj = 1, 3
          q(ii) = q(ii) + Dloc(ii, jj)
        end do
        q(ii) = alphaT * q(ii)
      end do
    end if

    call ContGauss(et_b, fm_base, cx_b, Therm_IpKernel)

    if (allocated(B))   deallocate(B)
    if (allocated(Buq)) deallocate(Buq)

    if (hasThermalField) then
      if (size(Ctx%temp) >= nNode) then
        do iNode = 1, nNode
          rowT = (iNode-1)*ndpn_total + ndpn_total
          if (rowT < 1 .or. rowT > size(Re)) cycle
          do jNode = 1, nNode
            colT = (jNode-1)*ndpn_total + ndpn_total
            if (colT < 1 .or. colT > size(Ke,2)) cycle
            Re(rowT) = Re(rowT) + Ke(rowT, colT) * Ctx%temp(jNode)
          end do
        end do
      end if
    end if

    if (effHasTransient) then
      allocate(T_new(nNode), T_old(nNode))
      do jNode = 1, nNode
        if (jNode <= size(Ctx%temp)) then
          T_new(jNode) = Ctx%temp(jNode)
        else
          T_new(jNode) = 0.0_wp
        end if
        if (jNode <= size(Ctx%temp_incr)) then
          T_old(jNode) = T_new(jNode) - Ctx%temp_incr(jNode)
        else
          T_old(jNode) = T_new(jNode)
        end if
      end do

      do iNode = 1, nNode
        rowT = (iNode-1)*ndpn_total + ndpn_total
        if (rowT < 1 .or. rowT > size(Re)) cycle
        do jNode = 1, nNode
          colT = (jNode-1)*ndpn_total + ndpn_total
          if (colT < 1 .or. colT > size(Ke,2)) cycle
          Ke(rowT, colT) = Ke(rowT, colT) + Ctt(iNode, jNode) / dt
          Re(rowT)       = Re(rowT)       + (Ctt(iNode, jNode) / dt) * &
                                         (T_new(jNode) - T_old(jNode))
        end do
      end do

      deallocate(T_new, T_old)
    end if

    if (totalVol > 0.0_wp .and. nDim > 0) then
      L_char = totalVol ** (1.0_wp / real(nDim, wp))
      if (hasTransient .and. k_cond > 0.0_wp .and. rho > 0.0_wp .and. c_p > 0.0_wp) then
        alpha_th    = k_cond / max(rho * c_p, 1.0e-16_wp)
        stableDt_th = 0.5_wp * L_char*L_char / max(alpha_th, 1.0e-16_wp)
      end if
    end if

    call UF_Element_CombineStableDt(stableDt_th, Ctx%dTime, flags)

    state_out%evo%Ke(1:nDOF_total,1:nDOF_total) = Ke(1:nDOF_total,1:nDOF_total)
    state_out%Re(1:nDOF_total)             = Re(1:nDOF_total)
    state_out%Me(1:nDOF_total,1:nDOF_total) = Me(1:nDOF_total,1:nDOF_total)
    state_out%Ce(1:nDOF_total,1:nDOF_total) = Ce(1:nDOF_total,1:nDOF_total)

    state_out%failed   = flags%failed
    state_out%stableDt = flags%stableDt

  contains

    subroutine Therm_IpKernel(ip, sf, dN_dx_ip, dVol_ip, radius_ip)
      integer(i4), intent(in) :: ip
      type(ShapeFuncResult), intent(in) :: sf
      real(wp), intent(in) :: dN_dx_ip(:,:)
      real(wp), intent(in) :: dVol_ip, radius_ip

      integer(i4) :: iNode, jNode, aDim, a
      integer(i4) :: rowT, colT, row_u, row_full
      real(wp) :: DeltaT_ip
      real(wp) :: dNx, dNy, dNz
      integer(i4) :: col

      totalVol = totalVol + dVol_ip

      if (k_cond > 0.0_wp) then
        do iNode = 1, nNode
          rowT = (iNode-1)*ndpn_total + ndpn_total
          do jNode = 1, nNode
            colT = (jNode-1)*ndpn_total + ndpn_total
            gradni_dot_grad = 0.0_wp
            do aDim = 1, nDim
              gradni_dot_grad = gradni_dot_grad + dN_dx_ip(iNode, aDim) * dN_dx_ip(jNode, aDim)
            end do
            Ke(rowT, colT) = Ke(rowT, colT) + k_cond * gradni_dot_grad * dVol_ip
          end do
        end do
      end if

      if (hasthermoexpans) then
        B = 0.0_wp
        do iNode = 1, nNode
          dNx = dN_dx_ip(iNode,1)
          dNy = dN_dx_ip(iNode,2)
          dNz = dN_dx_ip(iNode,3)
          col = (iNode-1)*ndpn_struct
          B(1, col+1) = dNx
          B(2, col+2) = dNy
          B(3, col+3) = dNz
          B(4, col+1) = dNy
          B(4, col+2) = dNx
          B(5, col+1) = dNz
          B(5, col+3) = dNx
          B(6, col+2) = dNz
          B(6, col+3) = dNy
        end do

        Buq = 0.0_wp
        Buq(1:nDOF_struct) = matmul(transpose(B(1:6,1:nDOF_struct)), q(1:6))

        DeltaT_ip = 0.0_wp
        if (hasThermalField) then
          do jNode = 1, nNode
            if (jNode <= size(Ctx%temp)) then
              DeltaT_ip = DeltaT_ip + sf%N(jNode, 1) * Ctx%temp(jNode)
            end if
          end do
        end if

        do iNode = 1, nNode
          do a = 1, ndpn_struct
            row_u    = (iNode-1)*ndpn_struct + a
            row_full = (iNode-1)*ndpn_total  + a
            if (row_full >= 1 .and. row_full <= size(Re)) then
              Re(row_full) = Re(row_full) + Buq(row_u) * DeltaT_ip * dVol_ip
            end if
          end do
        end do

        do jNode = 1, nNode
          colT = (jNode-1)*ndpn_total + ndpn_total
          if (colT < 1 .or. colT > size(Ke,2)) cycle
          do iNode = 1, nNode
            do a = 1, ndpn_struct
              row_u    = (iNode-1)*ndpn_struct + a
              row_full = (iNode-1)*ndpn_total  + a
              if (row_full < 1 .or. row_full > size(Ke,1)) cycle
              Ke(row_full, colT) = Ke(row_full, colT) + Buq(row_u) * sf%N(jNode, 1) * dVol_ip
            end do
          end do
        end do
      end if

      if (hasTransient) then
        real(wp) :: Nij
        do iNode = 1, nNode
          do jNode = 1, nNode
            Nij = sf%N(iNode, 1) * sf%N(jNode, 1)
            Ctt(iNode, jNode) = Ctt(iNode, jNode) + rho * c_p * Nij * dVol_ip
          end do
        end do
      end if

    end subroutine Therm_IpKernel

  end subroutine Calc_Continuum3D_Thermal

  subroutine Calc_Continuum3D_THM(ElemType, Formul, Ctx, state_in, &
                                     matModels, state_out, flags)
    type(UF_ElemType),        intent(in)    :: ElemType
    type(UF_ElemFormul), intent(in)    :: Formul
    type(UF_ElemCtx),     intent(in)    :: Ctx
    type(ElemState),       intent(in)    :: state_in
    type(UF_MaterialModel),      intent(in)    :: matModels(:)
    type(ElemState),       intent(inout) :: state_out
    type(UF_ElemFlags),       intent(out)   :: flags

    real(wp), pointer :: Ke(:,:), Re(:)
    real(wp), pointer :: Me(:,:), Ce(:,:)

    integer(i4) :: nNode, nDim
    integer(i4) :: ndpn_struct, ndpn_total
    integer(i4) :: nDOF_struct, nDOF_total
    integer(i4) :: iNode, jNode, kNode, a, b
    integer(i4) :: row_u, col_u, row_full, col_full
    integer(i4) :: idxT, idxP

    type(UF_ElemType) :: elemType_struct

    integer(i4) :: ip, aDim
    real(wp), allocatable :: Ctt(:,:)
    real(wp), allocatable :: Spp(:,:)
    real(wp), pointer     :: B(:,:), mB(:)

    real(wp) :: k_th, rho_s, c_p_s, rho_f, c_p_f, rhoCp, dt
    real(wp) :: alpha_b, k_hyd, S_s
    real(wp) :: m_vec(6)
    real(wp) :: volRate_ip, u_dot_loc
    real(wp) :: flag_vol
    real(wp) :: gradni_dot_grad
    real(wp) :: Nij
    real(wp) :: grad_p(3), v_darcy(3), v_dot_gradNi, v_dot_gradni_dp, T_ip, p_j
    real(wp) :: p_ip
    real(wp) :: totalVol, L_char, alpha_heat, alpha_poro, stableDt_heat, stableDt_poro

    type(MatProperties) :: props
    type(UF_THMPointState) :: thmState

    integer(i4) :: rowT, colT, rowP, colP
    integer(i4) :: ierr_material
    logical :: hasTempField, hasTempIncr
    logical :: hasPoreField, hasPoreIncr
    logical :: hasTransient_T, hasTransient_P, hasBiotCoupling
    logical :: ignoreCapacity, effhastransient, effhastransient
    logical :: volrate_materia, volRate_on
    type(ElemFormul) :: fm_b
    type(ElemType) :: et_b
    type(ElemCtx) :: cx_b
    type(ElemFlags) :: fl_b

    nNode = ElemType%pop%n_nodes
    nDim  = ElemType%dim

    if (nDim /= 3_i4) then
      flags%failed              = .true.
      flags%suggest_cutback     = .false.
      flags%requires_reasse = .false.
      flags%stableDt            = 0.0_wp
      call init_error_status(flags%status, IF_STATUS_INVALID, &
        message='Calc_Continuum3D_THM: expected ElemType%dim=3')
      state_out%failed   = flags%failed
      state_out%stableDt = flags%stableDt
      return
    end if

    ndpn_struct = 3
    ndpn_total  = ndpn_struct + 2
    idxT        = ndpn_struct + 1
    idxP        = ndpn_struct + 2

    nDOF_struct = nNode * ndpn_struct
    nDOF_total  = nNode * ndpn_total

    flags%failed              = .false.
    flags%suggest_cutback     = .false.
    flags%requires_reasse = .true.
    flags%stableDt            = 0.0_wp

    call RT_Elem_WS_GetMultiField(nDOF_total, Ke, Re, Me, Ce)

    elemType_struct = ElemType
    elemType_struct%n_dof_per_node = ndpn_struct

    et_b = elemType_struct
    cx_b = Ctx
    call PH_Contm_UF_Formul_to_ElemFormul(Formul, fm_b)
    call Calc_Continuum(et_b, fm_b, cx_b, state_in, &
                           matModels, state_out, fl_b)
    flags = fl_b

    call UF_Embed_StructBlock(nNode, ndpn_struct, ndpn_total, &
                              Ke, Re, Me, Ce, &
                              state_out%evo%Ke(1:nDOF_struct, 1:nDOF_struct), &
                              state_out%Re(1:nDOF_struct), &
                              state_out%Me(1:nDOF_struct, 1:nDOF_struct), &
                              state_out%Ce(1:nDOF_struct, 1:nDOF_struct))

    props  = matModels(1)%props

    thmState%mech%cfg%id    = matModels(1)%cfg%id
    thmState%thermal%cfg%id = matModels(1)%cfg%id
    thmState%poro%cfg%id    = matModels(1)%cfg%id

    thmState%mech%time     = Ctx%time_curr
    thmState%thermal%time  = Ctx%time_curr
    thmState%poro%time     = Ctx%time_curr

    thmState%mech%dtime    = Ctx%dTime
    thmState%thermal%dtime = Ctx%dTime
    thmState%poro%dtime    = Ctx%dTime

    call THMCoeffs(matModels(1), thmState, rho_s, k_th, c_p_s, &
                   rho_f, c_p_f, alpha_b, k_hyd, S_s, flag_vol, ierr_material)

    dt = max(Ctx%dTime, 0.0_wp)
    totalVol      = 0.0_wp
    stableDt_heat = 0.0_wp
    stableDt_poro = 0.0_wp

    hasTempField  = allocated(Ctx%temp)
    hasTempIncr   = allocated(Ctx%temp_incr)
    hasPoreField  = allocated(Ctx%pore)
    hasPoreIncr   = allocated(Ctx%pore_incr)

    rhoCp = rho_s * c_p_s + rho_f * c_p_f

    hasTransient_T   = (rhoCp > 0.0_wp .and. dt > 0.0_wp .and. hasTempField .and. hasTempIncr)
    hasBiotCoupling  = (alpha_b /= 0.0_wp)
    hasTransient_P   = (S_s > 0.0_wp .and. dt > 0.0_wp .and. hasPoreField .and. hasPoreIncr)

    ignoreCapacity     = Ctx%ignoreCapacity
    effhastransient  = hasTransient_T .and. .not. ignoreCapacity
    effhastransient  = hasTransient_P .and. .not. ignoreCapacity

    volrate_materia = (flag_vol > 0.5_wp)
    volRate_on  = (ENABLE_VOLRATE_COUPLING_DEFAULT .and. volrate_materia)

    if (effhastransient) then
      call THMAllocCtt(nNode, Ctt)
    end if

    if (effhastransient) then
      call THMAllocSpp(nNode, Spp)
    end if

    if (hasBiotCoupling) then
      call RT_Elem_WS_GetStructBm_2(nDOF_struct, B, mB)
      m_vec = 0.0_wp
      m_vec(1) = 1.0_wp
      m_vec(2) = 1.0_wp
      m_vec(3) = 1.0_wp
    end if

    call ContGauss(et_b, fm_b, cx_b, THM3D_IpKernel)

    if (totalVol > 0.0_wp .and. nDim > 0) then
      L_char = totalVol ** (1.0_wp / real(nDim, wp))

      if (hasTransient_T .and. k_th > 0.0_wp .and. rhoCp > 0.0_wp) then
        alpha_heat    = k_th / max(rhoCp, 1.0e-16_wp)
        stableDt_heat = 0.5_wp * L_char*L_char / max(alpha_heat, 1.0e-16_wp)
      end if

      if (hasTransient_P .and. k_hyd > 0.0_wp .and. S_s > 0.0_wp) then
        alpha_poro    = k_hyd / max(S_s, 1.0e-16_wp)
        stableDt_poro = 0.5_wp * L_char*L_char / max(alpha_poro, 1.0e-16_wp)
      end if
    end if

    call UF_Element_CombineStableDt(stableDt_heat, Ctx%dTime, flags)
    call UF_Element_CombineStableDt(stableDt_poro, Ctx%dTime, flags)

    if (hasTempField) then
      if (size(Ctx%temp) >= nNode) then
        do iNode = 1, nNode
          rowT = (iNode-1)*ndpn_total + idxT
          if (rowT < 1 .or. rowT > size(Re)) cycle
          do jNode = 1, nNode
            colT = (jNode-1)*ndpn_total + idxT
            if (colT < 1 .or. colT > size(Ke,2)) cycle
            Re(rowT) = Re(rowT) + Ke(rowT, colT) * Ctx%temp(jNode)
          end do
        end do
      end if
    end if

    if (effhastransient .and. allocated(Ctt)) then
      do iNode = 1, nNode
        rowT = (iNode-1)*ndpn_total + idxT
        if (rowT < 1 .or. rowT > size(Re)) cycle
        do jNode = 1, nNode
          colT = (jNode-1)*ndpn_total + idxT
          if (colT < 1 .or. colT > size(Ke,2)) cycle
          Ke(rowT, colT) = Ke(rowT, colT) + Ctt(iNode, jNode) / dt
          if (jNode <= size(Ctx%temp_incr)) then
            Re(rowT) = Re(rowT) + (Ctt(iNode, jNode) / dt) * Ctx%temp_incr(jNode)
          end if
        end do
      end do
    end if

    if (hasPoreField) then
      if (size(Ctx%pore) >= nNode) then
        do iNode = 1, nNode
          rowP = (iNode-1)*ndpn_total + idxP
          if (rowP < 1 .or. rowP > size(Re)) cycle
          do jNode = 1, nNode
            colP = (jNode-1)*ndpn_total + idxP
            if (colP < 1 .or. colP > size(Ke,2)) cycle
            Re(rowP) = Re(rowP) + Ke(rowP, colP) * Ctx%pore(jNode)
          end do
        end do
      end if
    end if

    if (effhastransient .and. allocated(Spp)) then
      do iNode = 1, nNode
        rowP = (iNode-1)*ndpn_total + idxP
        if (rowP < 1 .or. rowP > size(Re)) cycle
        do jNode = 1, nNode
          colP = (jNode-1)*ndpn_total + idxP
          if (colP < 1 .or. colP > size(Ke,2)) cycle
          Ke(rowP, colP) = Ke(rowP, colP) + Spp(iNode, jNode) / dt
          if (jNode <= size(Ctx%pore_incr)) then
            Re(rowP) = Re(rowP) + (Spp(iNode, jNode) / dt) * Ctx%pore_incr(jNode)
          end if
        end do
      end do
    end if

    state_out%evo%Ke(1:nDOF_total,1:nDOF_total) = Ke(1:nDOF_total,1:nDOF_total)
    state_out%Re(1:nDOF_total)             = Re(1:nDOF_total)
    state_out%Me(1:nDOF_total,1:nDOF_total) = Me(1:nDOF_total,1:nDOF_total)
    state_out%Ce(1:nDOF_total,1:nDOF_total) = Ce(1:nDOF_total,1:nDOF_total)

    state_out%failed   = flags%failed
    state_out%stableDt = flags%stableDt

  contains

    subroutine THM3D_IpKernel(ip, sf, dN_dx_ip, dVol_ip, radius_ip)
      integer(i4), intent(in) :: ip
      type(ShapeFuncResult), intent(in) :: sf
      real(wp), intent(in) :: dN_dx_ip(:,:)
      real(wp), intent(in) :: dVol_ip, radius_ip

      integer(i4) :: iNode, jNode, aDim, col
      integer(i4) :: rowT, colT, rowP, colP, row_full
      real(wp)    :: dNx, dNy, dNz
      real(wp)    :: v_dot_gradNi, v_dot_gradni_dp
      real(wp)    :: volRate_loc

      totalVol = totalVol + dVol_ip

      if (k_th > 0.0_wp) then
        do iNode = 1, nNode
          rowT = (iNode-1)*ndpn_total + idxT
          do jNode = 1, nNode
            colT = (jNode-1)*ndpn_total + idxT

            gradni_dot_grad = 0.0_wp
            do aDim = 1, nDim
              gradni_dot_grad = gradni_dot_grad + dN_dx_ip(iNode, aDim) * dN_dx_ip(jNode, aDim)
            end do

            Ke(rowT, colT) = Ke(rowT, colT) + k_th * gradni_dot_grad * dVol_ip

          end do
        end do
      end if

      if (hasTransient_T .and. effhastransient) then
        do iNode = 1, nNode
          do jNode = 1, nNode
            Nij = sf%N(iNode, 1) * sf%N(jNode, 1)
            Ctt(iNode, jNode) = Ctt(iNode, jNode) + rhoCp * Nij * dVol_ip
          end do
        end do
      end if

      if (k_hyd > 0.0_wp) then
        do iNode = 1, nNode
          rowP = (iNode-1)*ndpn_total + idxP
          do jNode = 1, nNode
            colP = (jNode-1)*ndpn_total + idxP

            gradni_dot_grad = 0.0_wp
            do aDim = 1, nDim
              gradni_dot_grad = gradni_dot_grad + dN_dx_ip(iNode, aDim) * dN_dx_ip(jNode, aDim)
            end do

            Ke(rowP, colP) = Ke(rowP, colP) + k_hyd * gradni_dot_grad * dVol_ip
          end do
        end do
      end if

      if (rho_f > 0.0_wp .and. c_p_f > 0.0_wp .and. k_hyd > 0.0_wp &
          .and. hasTempField .and. hasPoreField) then

        grad_p = 0.0_wp
        do jNode = 1, nNode
          if (jNode <= size(Ctx%pore)) then
            p_j = Ctx%pore(jNode)
          else
            p_j = 0.0_wp
          end if
          do aDim = 1, nDim
            grad_p(aDim) = grad_p(aDim) + dN_dx_ip(jNode, aDim) * p_j
          end do
        end do

        v_darcy = 0.0_wp
        do aDim = 1, nDim
          v_darcy(aDim) = -k_hyd * grad_p(aDim)
        end do

        T_ip = 0.0_wp
        do jNode = 1, nNode
          if (jNode <= size(Ctx%temp)) then
            T_ip = T_ip + sf%N(jNode, 1) * Ctx%temp(jNode)
          end if
        end do

        do iNode = 1, nNode
          rowT = (iNode-1)*ndpn_total + idxT
          if (rowT < 1 .or. rowT > size(Re)) cycle

          v_dot_gradNi = 0.0_wp
          do aDim = 1, nDim
            v_dot_gradNi = v_dot_gradNi + v_darcy(aDim) * dN_dx_ip(iNode, aDim)
          end do

          Re(rowT) = Re(rowT) + rho_f * c_p_f * v_dot_gradNi * T_ip * dVol_ip
        end do

        do iNode = 1, nNode
          rowT = (iNode-1)*ndpn_total + idxT
          if (rowT < 1 .or. rowT > size(Ke,1)) cycle

          v_dot_gradNi = 0.0_wp
          do aDim = 1, nDim
            v_dot_gradNi = v_dot_gradNi + v_darcy(aDim) * dN_dx_ip(iNode, aDim)
          end do

          do jNode = 1, nNode
            colT = (jNode-1)*ndpn_total + idxT
            if (colT < 1 .or. colT > size(Ke,2)) cycle
            Ke(rowT, colT) = Ke(rowT, colT) + rho_f * c_p_f * v_dot_gradNi * sf%N(jNode, 1) * dVol_ip
          end do
        end do

        do kNode = 1, nNode
          colP = (kNode-1)*ndpn_total + idxP
          if (colP < 1 .or. colP > size(Ke,2)) cycle

          do iNode = 1, nNode
            rowT = (iNode-1)*ndpn_total + idxT
            if (rowT < 1 .or. rowT > size(Ke,1)) cycle

            v_dot_gradni_dp = 0.0_wp
            do aDim = 1, nDim
              v_dot_gradni_dp = v_dot_gradni_dp - k_hyd * dN_dx_ip(kNode, aDim) * dN_dx_ip(iNode, aDim)
            end do

            Ke(rowT, colP) = Ke(rowT, colP) + rho_f * c_p_f * v_dot_gradni_dp * T_ip * dVol_ip
          end do
        end do

      end if

      if (hasBiotCoupling .and. hasPoreField) then
        B = 0.0_wp
        do iNode = 1, nNode
          dNx = dN_dx_ip(iNode,1)
          dNy = dN_dx_ip(iNode,2)
          dNz = dN_dx_ip(iNode,3)
          col = (iNode-1)*ndpn_struct
          B(1, col+1) = dNx
          B(2, col+2) = dNy
          B(3, col+3) = dNz
          B(4, col+1) = dNy
          B(4, col+2) = dNx
          B(5, col+1) = dNz
          B(5, col+3) = dNx
          B(6, col+2) = dNz
          B(6, col+3) = dNy
        end do

        mB = 0.0_wp
        mB(1:nDOF_struct) = matmul(transpose(B(1:6,1:nDOF_struct)), m_vec(1:6))

        p_ip = 0.0_wp
        if (size(Ctx%pore) >= nNode) then
          do jNode = 1, nNode
            p_ip = p_ip + sf%N(jNode, 1) * Ctx%pore(jNode)
          end do
        end if

        do iNode = 1, nNode
          do a = 1, ndpn_struct
            row_u    = (iNode-1)*ndpn_struct + a
            row_full = (iNode-1)*ndpn_total  + a
            if (row_full >= 1 .and. row_full <= size(Re)) then
              Re(row_full) = Re(row_full) - alpha_b * mB(row_u) * p_ip * dVol_ip
            end if
          end do
        end do

        do jNode = 1, nNode
          colP = (jNode-1)*ndpn_total + idxP
          if (colP < 1 .or. colP > size(Ke,2)) cycle
          do iNode = 1, nNode
            do a = 1, ndpn_struct
              row_u    = (iNode-1)*ndpn_struct + a
              row_full = (iNode-1)*ndpn_total  + a
              if (row_full < 1 .or. row_full > size(Ke,1)) cycle
              Ke(row_full, colP) = Ke(row_full, colP) - alpha_b * mB(row_u) * sf%N(jNode, 1) * dVol_ip
            end do
          end do
        end do
      end if

      if (effhastransient) then
        do iNode = 1, nNode
          do jNode = 1, nNode
            Nij = sf%N(iNode, 1) * sf%N(jNode, 1)
            Spp(iNode, jNode) = Spp(iNode, jNode) + S_s * Nij * dVol_ip
          end do
        end do
      end if

      if (hasTransient_P .and. hasBiotCoupling .and. volRate_on) then

        volRate_loc = 0.0_wp
        if (dt > 0.0_wp) then
          do iNode = 1, nNode
            do a = 1, ndpn_struct
              row_u = (iNode-1)*ndpn_struct + a
              if (a <= size(Ctx%disp_incr,1) .and. iNode <= size(Ctx%disp_incr,2)) then
                u_dot_loc = Ctx%disp_incr(a, iNode) / dt
              else
                u_dot_loc = 0.0_wp
              end if
              volRate_loc = volRate_loc + mB(row_u) * u_dot_loc
            end do
          end do
        end if

        if (abs(volRate_loc) > 0.0_wp) then
          do iNode = 1, nNode
            rowP = (iNode-1)*ndpn_total + idxP
            if (rowP < 1 .or. rowP > size(Re)) cycle
            Re(rowP) = Re(rowP) + alpha_b * volRate_loc * sf%N(iNode, 1) * dVol_ip
          end do

          if (dt > 0.0_wp) then
            do iNode = 1, nNode
              rowP = (iNode-1)*ndpn_total + idxP
              if (rowP < 1 .or. rowP > size(Ke,1)) cycle
              do jNode = 1, nNode
                do a = 1, ndpn_struct
                  col_u    = (jNode-1)*ndpn_struct + a
                  col_full = (jNode-1)*ndpn_total  + a
                  if (col_full < 1 .or. col_full > size(Ke,2)) cycle
                  Ke(rowP, col_full) = Ke(rowP, col_full) + alpha_b * sf%N(iNode, 1) * mB(col_u) * dVol_ip / dt
                end do
              end do
            end do
          end if
        end if
      end if

    end subroutine THM3D_IpKernel

  end subroutine Calc_Continuum3D_THM

  subroutine Calc_Continuum_Base(ElemType, Formul, Ctx, state_in, &
                                    matModels, state_out, flags)
    type(ElemType),       intent(in)    :: ElemType
    type(ElemFormul), intent(in)    :: Formul
    type(ElemCtx),    intent(in)    :: Ctx
    type(ElemState),         intent(in)    :: state_in
    type(UF_MaterialModel),  intent(in)    :: matModels(:) ! Array for IPs
    type(ElemState),         intent(inout) :: state_out
    type(ElemFlags),      intent(out)   :: flags
    
    ! Local variables
    integer(i4) :: nNode, nDim, nDOF, nInt
    real(wp), allocatable :: gaussCoords(:,:), weights(:)

    real(wp), pointer :: B(:,:)          ! 6 x nDOF B-matrix
    real(wp) :: sigma(6), D(6,6)
    
    ! Local stiffness/force/mass/damping matrices (final values written into state_out)

    real(wp), pointer :: Ke(:,:), Re(:)
    real(wp), pointer :: Me(:,:), Ce(:,:)
    
    ! Kinematics
    type(Kinematics) :: kin
    type(MatProperties)   :: props
    type(StructMatRes) :: physRes

    type(MatDescription) :: desc
    type(IPState)        :: ipState_in_zero
    integer(i4) :: ntens

    integer(i4) :: integrationorde
    logical :: isAxisym

    ! Explicit / Hourglass
    real(wp) :: totalVol
    logical  :: use_hourglass

    ! Mat flags + Element flags aggregation
    logical  :: element_failed
    real(wp) :: element_pnewdt
    real(wp) :: stableDt_wave
    
    ! Init flags
    flags%failed              = .false.
    flags%suggest_cutback     = .false.
    flags%requires_reasse = .true.
    flags%stableDt            = 0.0_wp

    element_failed      = .false.
    element_pnewdt  = 1.0_wp
    stableDt_wave    = 0.0_wp

    ! Phase 0: Dimension/Flag Initialization
    !-----------------------------------------------------------------
    nNode = PH_Contm_NNodes_Base(ElemType)
    nDim  = ElemType%dim
    nDOF  = nNode * ElemType%n_dof_per_node

    !-----------------------------------------------------------------
    ! Phase 1: Allocate local matrices/vectors and ws
    !-----------------------------------------------------------------
    call UF_Continuum_AllocWork(nDOF, Ke, Re, Me, Ce, B)

    !-----------------------------------------------------------------
    ! Phase 2: Determine tensor layout (ntens/ndi/nshr) and B-bar dispatch
    !-----------------------------------------------------------------
    ! Determine ntens based on Section descriptor
    desc  = StructGetSectionDesc(Ctx%cfg%id)
    ntens = 6_i4
    if (desc%valid .and. desc%ntens > 0_i4) then
      ntens = desc%ntens
    end if
    if (ntens > 6_i4) ntens = 6_i4

    isAxisym = (index(ElemType%name, 'CAX') > 0)
    
    ! Determine Integration Order (Shared rule with GaussKernel)
    integrationorde = GetEffOrder(ElemType, Formul)
    
    ! Hourglass Ctrl Check (Reduced Integration Linear Elements)
    use_hourglass = .false.
    if (index(ElemType%name, 'R') > 0 .and. integrationorde == 1) then
        use_hourglass = .true.
    end if

  !-----------------------------------------------------------------
  ! Phase 3: Gauss integration loop (Geometry -> Kinematics -> Fields -> Mat -> Assembly)
  !   Kinematics:
  !     - Large disp TL/UL: E(GL) = 0.5 (F^T F - I), F/C/gamma provided by KineEval
  !     - Small disp: eps = sym(grad u), axisym adds eps_theta = u_r / r
  !   B-matrix (Voigt order 11,22,33,12,13,23; 2D/AXI contains only relevant components):
  !     - Small disp: B_small * u approx eps
  !     - TL: B_TL = (F * grad0 N)_sym, shear as engineering strain (x2)
  !   Local Stiffness / Internal Force:
  !     Re      = integral B^T sigma dV
  !     Ke_material  = integral B^T D B dV (D is 6x6 Mat tangent)
  !     K_geo   = integral (grad N * grad N) : sigma dV, axisym adds stress_theta * N_i N_j / r^2
  !   Mass (2D/3D/AXI):
  !     Me = integral rho N^T N dV (Consistent / Lumped), axisym adds 2*pi*r
  !   Volume weight:
  !     dV = detJ * w (3D/2D), axisym adds 2*pi*r, r = sum N_i x_i
  !-----------------------------------------------------------------
    ! Get Gauss Points
    call UF_GetGaussPoints(ElemType%topo, integrationorde, nDim, gaussCoords, weights)
    nInt = size(weights)

    ! Protected allocation: ensure state_out%ipStates covers integration points
    if (.not. allocated(state_out%ipStates)) then
      allocate(state_out%ipStates(nInt))
    else if (size(state_out%ipStates) < nInt) then
      deallocate(state_out%ipStates)
      allocate(state_out%ipStates(nInt))
    end if

    ! Loop over Integration Points: handled by GaussKernel (including Jacobian/Axisymmetric volume correction)
    totalVol = 0.0_wp
    call StructGaussKernel(ElemType, Formul, Ctx, Continuum_IpKernel)
    
    !-----------------------------------------------------------------
    ! Phase 4: Hourglass (Post-Integration Add-on for reduced integration linear elements)
    !-----------------------------------------------------------------
    ! Hourglass Ctrl (Post-Integration Add-on)
    if (use_hourglass) then
      call UF_Continuum_ApplyHourglass(ElemType, Formul, Ctx, nNode, nDim, nDOF, isAxisym, totalVol, matModels(1)%props, D, Ke, Re)
    end if
    
    !-----------------------------------------------------------------
    ! Phase 5: Explicit stability step estimation + PNEWDT aggregation
    !-----------------------------------------------------------------
    stableDt_wave = 0.0_wp
    call UF_Continuum_EstimateStableDt(ElemType%name, nDim, isAxisym, totalVol, matModels(1)%props, stableDt_wave)

    ! Aggregate Mat flags: failed / pnewdt_factor
    call UF_Element_AggregateMaterialFlags(element_failed, element_pnewdt, Ctx%dTime, &
                                           stableDt_wave, flags)

    !-----------------------------------------------------------------
    ! Phase 6: Write back state_out (Ke/Re/Me/Ce unified cache)
    !-----------------------------------------------------------------
    call UF_Continuum_WriteBackState(state_out, Ke, Re, Me, Ce, nDOF)

    ! Write back Element-level flags to Element state for StepDriver use
    state_out%failed   = flags%failed
    state_out%stableDt = flags%stableDt

  contains

    subroutine Continuum_IpKernel(ip, sf, dN_dx_ip, dVol_ip, radius_ip)
      integer(i4), intent(in) :: ip
      type(ShapeFuncResult), intent(in) :: sf
      real(wp), intent(in) :: dN_dx_ip(:,:)
      real(wp), intent(in) :: dVol_ip, radius_ip
      logical :: isExplicitStep

      totalVol = totalVol + dVol_ip
      isExplicitStep = Ctx%isExplicit

      ! Compute Kinematics
      call KineEval(Ctx, sf, dN_dx_ip, Formul%kineFormulation, nDim, isAxisym, radius_ip, kin)

      ! Sync tensor layout/analysis type from Section descriptor to kin%meta
      kin%meta%kine_class     = Formul%kinematics
      kin%meta%Formul    = Formul%kineFormulation
      kin%meta%dim            = nDim
      kin%meta%ndi            = desc%ndi
      kin%meta%nshr           = desc%nshr
      kin%meta%ntens          = ntens

      kin%meta%analysis_type  = UF_UMAT_ANALYSI
      if (allocated(state_in%ipStates) .and. size(state_in%ipStates) >= ip) then
        if (allocated(state_in%ipStates(ip)%stateV)) then
          if (size(state_in%ipStates(ip)%stateV) >= 1) then
            kin%meta%analysis_type = nint(state_in%ipStates(ip)%stateV(1))
          end if
        end if
      end if
      if (kin%meta%analysis_type < UF_UMAT_ANALYSI .or. kin%meta%analysis_type > UF_UMAT_ANALYSI) &
        kin%meta%analysis_type = UF_UMAT_ANALYSI

      ! Multi-physics / predefined fields: Interpolate and write to kin%predef/user_real
      if (allocated(state_in%ipStates) .and. size(state_in%ipStates) >= ip) then
        call FillPredef(Ctx, state_in%ipStates(ip), sf, dN_dx_ip, nDim, kin)
      else
        call FillPredef(Ctx, ipState_in_zero, sf, dN_dx_ip, nDim, kin)
      end if

      ! Mat Integration: via physical model layer
      if (allocated(state_in%ipStates) .and. size(state_in%ipStates) >= ip) then
        call StructIntegrateIp(matModels(ip), Ctx, kin, desc, &
                               state_in%ipStates(ip), state_out%ipStates(ip), physRes, ip)
      else
        call StructIntegrateIp(matModels(ip), Ctx, kin, desc, &
                               ipState_in_zero, state_out%ipStates(ip), physRes, ip)
      end if
      sigma = physRes%core%stress6
      D      = physRes%core%D6

      ! Aggregate Mat flags -> Element-level cutback suggestion
      if (physRes%core%flags%failed) element_failed = .true.
      if (physRes%core%flags%pnewdt_factor > 0.0_wp) then
        element_pnewdt = min(element_pnewdt, physRes%core%flags%pnewdt_factor)
      end if

      props = matModels(ip)%props

      ! Form B-Matrix: handles small/large disp (TL/UL)
      call FormB(dN_dx_ip, sf%N, nNode, nDim, isAxisym, radius_ip, B, Formul%kineFormulation, kin%mech%F)

      ! Integrate Internal Force
      Re(1:nDOF) = Re(1:nDOF) + matmul(transpose(B(1:ntens, 1:nDOF)), sigma(1:ntens)) * dVol_ip

      ! Explicit Dynamics: elements only need internal force and mass; Implicit needs consistent tangent + geometric stiffness
      if (.not. isExplicitStep) then
        ! Integrate Stiffness Matrix
        Ke(1:nDOF, 1:nDOF) = Ke(1:nDOF, 1:nDOF) + &
                             matmul(transpose(B(1:ntens, 1:nDOF)), matmul(D(1:ntens,1:ntens), B(1:ntens, 1:nDOF))) * dVol_ip

        ! Geometric Stiffness
        if (Ctx%largeDisp) then
          call AddGeoK(Ke, dN_dx_ip, sf%N, sigma, dVol_ip, nNode, nDim, nDOF, isAxisym, radius_ip)
        end if
      end if

      ! Mass Matrix: always accumulate mass to Me
      call AddMass(Me, sf%N, props%density, dVol_ip, nNode, nDOF, Formul%dyn%mass_type)

    end subroutine Continuum_IpKernel

  end subroutine Calc_Continuum_Base

  subroutine Calc_Continuum_MatProps(ElemType, Formul, Ctx, state_in, &
                                        Mat, state_out, flags)
    type(ElemType),       intent(in)    :: ElemType
    type(ElemFormul), intent(in)    :: Formul
    type(ElemCtx),    intent(in)    :: Ctx
    type(ElemState),         intent(in)    :: state_in
    type(MatProperties),  intent(in)    :: Mat
    type(ElemState),         intent(inout) :: state_out
    type(ElemFlags),      intent(out)   :: flags

    type(UF_MaterialModel), allocatable :: matModels(:)
    integer(i4) :: nIP

    nIP = max(1_i4, ElemType%n_int_points)
    allocate(matModels(nIP))
    matModels(1)%cfg%id = Mat%material_id
    matModels(1)%props = Mat
    if (nIP > 1) then
      matModels(2:nIP) = matModels(1)
    end if
    call Calc_Continuum(ElemType, Formul, Ctx, state_in, matModels, state_out, flags)
    deallocate(matModels)
  end subroutine Calc_Continuum_MatProps

  subroutine Calc_Continuum_Poro(ElemType, Formul, Ctx, state_in, &
                                   matModels, state_out, flags)
    type(ElemType),       intent(in)    :: ElemType
    type(ElemFormul), intent(in)    :: Formul
    type(ElemCtx),    intent(in)    :: Ctx
    type(ElemState),         intent(in)    :: state_in
    type(UF_MaterialModel),  intent(in)    :: matModels(:)
    type(ElemState),         intent(inout) :: state_out
    type(ElemFlags),      intent(out)   :: flags

    real(wp), pointer :: Ke(:,:), Re(:)
    real(wp), pointer :: Me(:,:), Ce(:,:)

    integer(i4) :: nNode, nDim
    integer(i4) :: ndpn_struct, ndpn_total
    integer(i4) :: nDOF_struct, nDOF_total
    integer(i4) :: iNode, jNode, a, b
    integer(i4) :: row_u, col_u, row_full, col_full

    type(UF_ElemType) :: elemType_struct

    integer(i4) :: ip
    logical     :: isAxisym
    real(wp), pointer     :: Spp(:,:)

    real(wp), allocatable :: B(:,:), mB(:)
    real(wp), allocatable :: p_new(:), p_old(:)
    real(wp) :: alpha_b, k_hyd, S_s, dt
    logical  :: ignoreCapacity, effHasTransient
    real(wp) :: totalVol, L_char, alpha_poro, stableDt_poro

    real(wp) :: rho_fluid, cp_fluid
    real(wp) :: m_vec(6)
    real(wp) :: volRate_ip, u_dot_loc
    real(wp) :: flag_vol
    type(MatProperties) :: props
    type(UF_PoroPointState) :: prState

    integer(i4) :: rowP, colP
    logical :: hasPoreField, hasPoreIncr, hasBiotCoupling, hasTransient
    logical :: volrate_materia, volRate_on

    integer(i4) :: ierr_material

    logical :: use_bbar_poro
    real(wp), allocatable :: dN_bar_h(:,:)
    real(wp) :: totalVol_h

    nNode = PH_Contm_NNodes_Base(ElemType)
    nDim  = ElemType%dim

    if (nDim == 3_i4) then
      ndpn_struct = 3
    else
      ndpn_struct = 2
    end if

    ndpn_total  = ndpn_struct + 1
    nDOF_struct = nNode * ndpn_struct
    nDOF_total  = nNode * ndpn_total

    flags%failed              = .false.
    flags%suggest_cutback     = .false.
    flags%requires_reasse = .true.
    flags%stableDt            = 0.0_wp

    call RT_Elem_WS_GetMultiField(nDOF_total, Ke, Re, Me, Ce)

    elemType_struct = ElemType
    elemType_struct%n_dof_per_node = ndpn_struct

    call Calc_Continuum(elemType_struct, Formul, Ctx, state_in, &
                           matModels, state_out, flags)

    call UF_Embed_StructBlock(nNode, ndpn_struct, ndpn_total, &
                              Ke, Re, Me, Ce, &
                              state_out%evo%Ke(1:nDOF_struct, 1:nDOF_struct), &
                              state_out%Re(1:nDOF_struct), &
                              state_out%Me(1:nDOF_struct, 1:nDOF_struct), &
                              state_out%Ce(1:nDOF_struct, 1:nDOF_struct))

    props   = matModels(1)%props

    call PoroCoeffs(matModels(1), Ctx, alpha_b, k_hyd, S_s, &
                    rho_fluid, cp_fluid, flag_vol, hasTransient, &
                    prState, ierr_material)

    dt       = max(Ctx%dTime, 0.0_wp)
    totalVol = 0.0_wp
    stableDt_poro = 0.0_wp

    hasPoreField   = allocated(Ctx%pore)
    hasPoreIncr    = allocated(Ctx%pore_incr)
    hasBiotCoupling = (alpha_b /= 0.0_wp)

    ignoreCapacity  = Ctx%ignoreCapacity
    effHasTransient = hasTransient .and. .not. ignoreCapacity

    volrate_materia = (flag_vol > 0.5_wp)
    volRate_on  = (ENABLE_VOLRATE_COUPLING_DEFAULT .and. volrate_materia)

    use_bbar_poro = Formul%use_bbar
    if (.not. use_bbar_poro) then
      if (Formul%integration_scheme == UF_Int_Selective) use_bbar_poro = .true.
    end if

    if (hasBiotCoupling) then
      allocate(B(6, nDOF_struct))
      allocate(mB(nDOF_struct))
      m_vec = 0.0_wp
      m_vec(1) = 1.0_wp
      m_vec(2) = 1.0_wp
      m_vec(3) = 1.0_wp
    end if

    if (effHasTransient) then
      call PoroAllocSpp(nNode, Spp)
    end if

    isAxisym = (index(ElemType%name, 'CAX') > 0)

    call ContGauss(ElemType, Formul, Ctx, Poro_IpKernel)

    if (use_bbar_poro .and. k_hyd > 0.0_wp) then
      if ((ElemType%topo == UF_Topo_Quad .and. nNode == 4) .or. &
          (ElemType%topo == UF_Topo_Hex .and. nNode == 8)) then
        allocate(dN_bar_h(nNode, nDim))
        dN_bar_h  = 0.0_wp
        totalVol_h = 0.0_wp

        call ContGauss(ElemType, Formul, Ctx, Poro_Hpp_BBar_FirstPass)

        if (totalVol_h > 0.0_wp) then
          dN_bar_h(:,:) = dN_bar_h(:,:) / totalVol_h
          call ContGauss(ElemType, Formul, Ctx, Poro_Hpp_BBar_SecondPass)
        end if

        deallocate(dN_bar_h)
      end if
    end if

    if (hasPoreField) then
      if (size(Ctx%pore) >= nNode) then
        do iNode = 1, nNode
          rowP = (iNode-1)*ndpn_total + ndpn_total
          if (rowP < 1 .or. rowP > size(Re)) cycle
          do jNode = 1, nNode
            colP = (jNode-1)*ndpn_total + ndpn_total
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
        rowP = (iNode-1)*ndpn_total + ndpn_total
        if (rowP < 1 .or. rowP > size(Re)) cycle
        do jNode = 1, nNode
          colP = (jNode-1)*ndpn_total + ndpn_total
          if (colP < 1 .or. colP > size(Ke,2)) cycle
          Ke(rowP, colP) = Ke(rowP, colP) + Spp(iNode, jNode) / dt
          Re(rowP)       = Re(rowP)       + (Spp(iNode, jNode) / dt) * &
                                         (p_new(jNode) - p_old(jNode))
        end do
      end do

      deallocate(p_new, p_old)
    end if

    if (allocated(B))   deallocate(B)
    if (allocated(mB))  deallocate(mB)

    if (totalVol > 0.0_wp .and. nDim > 0) then
      L_char = totalVol ** (1.0_wp / real(nDim, wp))
      if (hasTransient .and. k_hyd > 0.0_wp .and. S_s > 0.0_wp) then
        alpha_poro   = k_hyd / max(S_s, 1.0e-16_wp)
        stableDt_poro = 0.5_wp * L_char*L_char / max(alpha_poro, 1.0e-16_wp)
      end if
    end if

    call UF_Element_CombineStableDt(stableDt_poro, Ctx%dTime, flags)

    state_out%evo%Ke(1:nDOF_total,1:nDOF_total) = Ke(1:nDOF_total,1:nDOF_total)
    state_out%Re(1:nDOF_total)             = Re(1:nDOF_total)
    state_out%Me(1:nDOF_total,1:nDOF_total) = Me(1:nDOF_total,1:nDOF_total)
    state_out%Ce(1:nDOF_total,1:nDOF_total) = Ce(1:nDOF_total,1:nDOF_total)

    state_out%failed   = flags%failed
    state_out%stableDt = flags%stableDt

  contains

    subroutine Poro_IpKernel(ip, sf, dN_dx_ip, dVol_ip, radius_ip)
      integer(i4), intent(in) :: ip
      type(ShapeFuncResult), intent(in) :: sf
      real(wp), intent(in) :: dN_dx_ip(:,:)
      real(wp), intent(in) :: dVol_ip, radius_ip

      integer(i4) :: iNode, jNode, a, aDim, col
      integer(i4) :: rowP, colP, row_u, row_full
      real(wp) :: gradni_dot_grad
      real(wp) :: dNx, dNy, dNz
      real(wp) :: Nij
      real(wp) :: p_ip

      totalVol = totalVol + dVol_ip

      if (k_hyd > 0.0_wp) then
        do iNode = 1, nNode
          rowP = (iNode-1)*ndpn_total + ndpn_total
          do jNode = 1, nNode
            colP = (jNode-1)*ndpn_total + ndpn_total

            gradni_dot_grad = 0.0_wp
            do aDim = 1, nDim
              gradni_dot_grad = gradni_dot_grad + dN_dx_ip(iNode, aDim) * dN_dx_ip(jNode, aDim)
            end do

            Ke(rowP, colP) = Ke(rowP, colP) + k_hyd * gradni_dot_grad * dVol_ip
          end do
        end do
      end if

      if (hasBiotCoupling .and. hasPoreField) then
        B = 0.0_wp
        do iNode = 1, nNode
          dNx = dN_dx_ip(iNode,1)
          dNy = dN_dx_ip(iNode,2)
          col = (iNode-1)*ndpn_struct
          B(1, col+1) = dNx
          B(2, col+2) = dNy
          B(4, col+1) = dNy
          B(4, col+2) = dNx
          if (nDim == 3) then
            dNz = dN_dx_ip(iNode,3)
            B(3, col+3) = dNz
            B(5, col+1) = dNz
            B(5, col+3) = dNx
            B(6, col+2) = dNz
            B(6, col+3) = dNy
          else if (isAxisym) then
            if (radius_ip > 1.0e-12_wp) then
              B(3, col+1) = sf%N(iNode, 1) / radius_ip
            else
              B(3, col+1) = sf%N(iNode, 1) / 1.0e-12_wp
            end if
          end if
        end do

        mB = 0.0_wp
        mB(1:nDOF_struct) = matmul(transpose(B(1:6,1:nDOF_struct)), m_vec(1:6))

        p_ip = 0.0_wp
        if (size(Ctx%pore) >= nNode) then
          do jNode = 1, nNode
            p_ip = p_ip + sf%N(jNode, 1) * Ctx%pore(jNode)
          end do
        end if

        do iNode = 1, nNode
          do a = 1, ndpn_struct
            row_u    = (iNode-1)*ndpn_struct + a
            row_full = (iNode-1)*ndpn_total  + a
            if (row_full >= 1 .and. row_full <= size(Re)) then
              Re(row_full) = Re(row_full) - alpha_b * mB(row_u) * p_ip * dVol_ip
            end if
          end do
        end do

        do jNode = 1, nNode
          colP = (jNode-1)*ndpn_total + ndpn_total
          if (colP < 1 .or. colP > size(Ke,2)) cycle
          do iNode = 1, nNode
            do a = 1, ndpn_struct
              row_u    = (iNode-1)*ndpn_struct + a
              row_full = (iNode-1)*ndpn_total  + a
              if (row_full < 1 .or. row_full > size(Ke,1)) cycle
              Ke(row_full, colP) = Ke(row_full, colP) - alpha_b * mB(row_u) * sf%N(jNode, 1) * dVol_ip
            end do
          end do
        end do
      end if

      if (hasTransient) then
        do iNode = 1, nNode
          do jNode = 1, nNode
            Nij = sf%N(iNode, 1) * sf%N(jNode, 1)
            Spp(iNode, jNode) = Spp(iNode, jNode) + S_s * Nij * dVol_ip
          end do
        end do
      end if

      if (hasTransient .and. hasBiotCoupling .and. volRate_on) then
        volRate_ip = 0.0_wp
        if (dt > 0.0_wp) then
          do iNode = 1, nNode
            do a = 1, ndpn_struct
              row_u = (iNode-1)*ndpn_struct + a
              if (a <= size(Ctx%disp_incr,1) .and. iNode <= size(Ctx%disp_incr,2)) then
                u_dot_loc = Ctx%disp_incr(a, iNode) / dt
              else
                u_dot_loc = 0.0_wp
              end if
              volRate_ip = volRate_ip + mB(row_u) * u_dot_loc
            end do
          end do
        end if

        if (abs(volRate_ip) > 0.0_wp) then
          do iNode = 1, nNode
            rowP = (iNode-1)*ndpn_total + ndpn_total
            if (rowP < 1 .or. rowP > size(Re)) cycle
            Re(rowP) = Re(rowP) + alpha_b * volRate_ip * sf%N(iNode, 1) * dVol_ip
          end do

          if (dt > 0.0_wp) then
            do iNode = 1, nNode
              rowP = (iNode-1)*ndpn_total + ndpn_total
              if (rowP < 1 .or. rowP > size(Ke,1)) cycle
              do jNode = 1, nNode
                do a = 1, ndpn_struct
                  col_u    = (jNode-1)*ndpn_struct + a
                  col_full = (jNode-1)*ndpn_total  + a
                  if (col_full < 1 .or. col_full > size(Ke,2)) cycle
                  Ke(rowP, col_full) = Ke(rowP, col_full) + alpha_b * sf%N(iNode, 1) * mB(col_u) * dVol_ip / dt
                end do
              end do
            end do
          end if
        end if
      end if

    end subroutine Poro_IpKernel

    subroutine Poro_Hpp_BBar_FirstPass(ip, sf, dN_dx_ip, dVol_ip, radius_ip)
      integer(i4), intent(in) :: ip
      type(ShapeFuncResult), intent(in) :: sf
      real(wp), intent(in) :: dN_dx_ip(:,:)
      real(wp), intent(in) :: dVol_ip, radius_ip
      integer(i4) :: iNode, aDim

      totalVol_h = totalVol_h + dVol_ip
      do iNode = 1, nNode
        do aDim = 1, nDim
          dN_bar_h(iNode, aDim) = dN_bar_h(iNode, aDim) + dN_dx_ip(iNode, aDim) * dVol_ip
        end do
      end do
    end subroutine Poro_Hpp_BBar_FirstPass

    subroutine Poro_Hpp_BBar_SecondPass(ip, sf, dN_dx_ip, dVol_ip, radius_ip)
      integer(i4), intent(in) :: ip
      type(ShapeFuncResult), intent(in) :: sf
      real(wp), intent(in) :: dN_dx_ip(:,:)
      real(wp), intent(in) :: dVol_ip, radius_ip
      integer(i4) :: iNode, jNode, aDim
      integer(i4) :: rowP, colP
      real(wp) :: grad_std, grad_bar

      if (k_hyd <= 0.0_wp) return

      do iNode = 1, nNode
        rowP = (iNode-1)*ndpn_total + ndpn_total
        if (rowP < 1 .or. rowP > size(Ke,1)) cycle
        do jNode = 1, nNode
          colP = (jNode-1)*ndpn_total + ndpn_total
          if (colP < 1 .or. colP > size(Ke,2)) cycle

          grad_std = 0.0_wp
          grad_bar = 0.0_wp
          do aDim = 1, nDim
            grad_std = grad_std + dN_dx_ip(iNode, aDim) * dN_dx_ip(jNode, aDim)
            grad_bar = grad_bar + dN_bar_h(iNode, aDim) * dN_bar_h(jNode, aDim)
          end do

          Ke(rowP, colP) = Ke(rowP, colP) + k_hyd * (grad_bar - grad_std) * dVol_ip
        end do
      end do

    end subroutine Poro_Hpp_BBar_SecondPass

  end subroutine Calc_Continuum_Poro

  subroutine Calc_Continuum_Thermal(ElemType, Formul, Ctx, state_in, &
                                      matModels, state_out, flags)
    type(ElemType),       intent(in)    :: ElemType
    type(ElemFormul), intent(in)    :: Formul
    type(ElemCtx),    intent(in)    :: Ctx
    type(ElemState),         intent(in)    :: state_in
    type(UF_MaterialModel),  intent(in)    :: matModels(:)
    type(ElemState),         intent(inout) :: state_out
    type(ElemFlags),      intent(out)   :: flags

    if (ElemType%dim == 3) then
      block
        type(UF_ElemType) :: et_uf
        type(UF_ElemFormul) :: fm_uf
        type(UF_ElemCtx) :: cx_uf
        type(UF_ElemFlags) :: fl_uf
        call PH_Contm_Promote_to_UF_Therm3D(ElemType, Formul, Ctx, et_uf, fm_uf, cx_uf)
        call Calc_Continuum3D_Thermal(et_uf, fm_uf, cx_uf, state_in, &
             matModels, state_out, fl_uf)
        CALL PH_Contm_ElemFlags_copy_UF_to_base(flags, fl_uf)
      end block
    else
      call Calc_Continuum2D_Thermal(ElemType, Formul, Ctx, state_in, &
                                       matModels, state_out, flags)
    end if

  end subroutine Calc_Continuum_Thermal

  subroutine Calc_Continuum_THM(ElemType, Formul, Ctx, state_in, &
                                  matModels, state_out, flags)
    type(ElemType),       intent(in)    :: ElemType
    type(ElemFormul), intent(in)    :: Formul
    type(ElemCtx),    intent(in)    :: Ctx
    type(ElemState),         intent(in)    :: state_in
    type(UF_MaterialModel),  intent(in)    :: matModels(:)
    type(ElemState),         intent(inout) :: state_out
    type(ElemFlags),      intent(out)   :: flags

    if (ElemType%dim == 3) then
      block
        type(UF_ElemType) :: et_uf
        type(UF_ElemFormul) :: fm_uf
        type(UF_ElemCtx) :: cx_uf
        type(UF_ElemFlags) :: fl_uf
        call PH_Contm_Promote_to_UF_Therm3D(ElemType, Formul, Ctx, et_uf, fm_uf, cx_uf)
        call Calc_Continuum3D_THM(et_uf, fm_uf, cx_uf, state_in, &
             matModels, state_out, fl_uf)
        CALL PH_Contm_ElemFlags_copy_UF_to_base(flags, fl_uf)
      end block
    else
      call Calc_Continuum2D_THM(ElemType, Formul, Ctx, state_in, &
                                   matModels, state_out, flags)
    end if

  end subroutine Calc_Continuum_THM

  subroutine Calc_ElementVolume_Hex(coords, volume, status)
    !! Compute hex element volume using integration
    !!
    !! Algorithm:
    !!   V = integral det(J) dXi dEta dZeta
    !!   Use 2x2x2 Gauss integration
    
    real(wp), intent(in) :: coords(8, 3)
    real(wp), intent(out) :: volume
    type(ErrorStatusType), intent(out), optional :: status
    
    integer(i4) :: ip, n_ip, i
    real(wp), allocatable :: xi(:), eta(:), zeta(:), w(:)
    real(wp) :: N(8), dNdxi(8), dNdeta(8), dNdzeta(8)
    real(wp) :: Jac(3, 3), detJ
    
    if (present(status)) call init_error_status(status)
    
    ! Get 2x2x2 Gauss points (8 points)
    allocate(xi(8), eta(8), zeta(8), w(8))
    call gauss_hexahedron(2, xi, eta, zeta, w)
    
    n_ip = 8
    volume = 0.0_wp
    
    ! Integrate over element
    do ip = 1, n_ip
      ! Get shape functions and derivatives
      call shape_hex8(xi(ip), eta(ip), zeta(ip), N, dNdxi, dNdeta, dNdzeta)
      
      ! Compute Jacobian matrix
      Jac = 0.0_wp
      do i = 1, 8
        Jac(1, 1) = Jac(1, 1) + dNdxi(i) * coords(i, 1)
        Jac(1, 2) = Jac(1, 2) + dNdeta(i) * coords(i, 1)
        Jac(1, 3) = Jac(1, 3) + dNdzeta(i) * coords(i, 1)
        Jac(2, 1) = Jac(2, 1) + dNdxi(i) * coords(i, 2)
        Jac(2, 2) = Jac(2, 2) + dNdeta(i) * coords(i, 2)
        Jac(2, 3) = Jac(2, 3) + dNdzeta(i) * coords(i, 2)
        Jac(3, 1) = Jac(3, 1) + dNdxi(i) * coords(i, 3)
        Jac(3, 2) = Jac(3, 2) + dNdeta(i) * coords(i, 3)
        Jac(3, 3) = Jac(3, 3) + dNdzeta(i) * coords(i, 3)
      end do
      
      ! Compute determinant
      detJ = Jac(1,1) * (Jac(2,2)*Jac(3,3) - Jac(2,3)*Jac(3,2)) - &
             Jac(1,2) * (Jac(2,1)*Jac(3,3) - Jac(2,3)*Jac(3,1)) + &
             Jac(1,3) * (Jac(2,1)*Jac(3,2) - Jac(2,2)*Jac(3,1))
      
      ! Accumulate volume
      volume = volume + detJ * w(ip)
    end do
    
    deallocate(xi, eta, zeta, w)
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  end subroutine Calc_ElementVolume_Hex

  function Estimate_ElementVolume(coords) result(volume)
    !! Estimate element volume from bounding box (fallback)
    
    real(wp), intent(in) :: coords(8, 3)
    real(wp) :: volume
    
    real(wp) :: x_min, x_max, y_min, y_max, z_min, z_max
    integer(i4) :: i
    
    ! Find bounding box
    x_min = minval(coords(:, 1))
    x_max = maxval(coords(:, 1))
    y_min = minval(coords(:, 2))
    y_max = maxval(coords(:, 2))
    z_min = minval(coords(:, 3))
    z_max = maxval(coords(:, 3))
    
    ! Estimate volume as bounding box volume
    volume = (x_max - x_min) * (y_max - y_min) * (z_max - z_min)
    
  end function Estimate_ElementVolume

  SUBROUTINE PH_Elem_Contm_Calc3D(arg)
    TYPE(PH_Elem_Contm_Calc3D_Arg), INTENT(INOUT) :: arg
    
    LOGICAL :: use_bbar_effect
    
    ! Initialize output
    CALL init_error_status(arg%status)
    arg%state_out = arg%state_in
    ! Initialize flags with default values
    arg%flags%failed = .FALSE.
    arg%flags%suggest_cutback = .FALSE.
    arg%flags%requires_reasse = .FALSE.
    arg%flags%stableDt = 0.0_wp
    CALL init_error_status(arg%flags%status)
    arg%flags%stp%nlgeom = 0_i4
    arg%flags%formulation_typ = 0_i4
    
    IF (arg%elem_type%dim /= 3_i4) THEN
      ! Only 3D structural elements are expected
      arg%flags%failed = .TRUE.
      CALL init_error_status(arg%flags%status, IF_STATUS_INVALID, &
        message='PH_Elem_Contm_Calc3D: invalid element dimension (expected 3D)')
      arg%status = arg%flags%status
      RETURN
    END IF

    ! Determine if B-bar effect is needed
    use_bbar_effect = arg%formul%use_bbar
    IF (.NOT. use_bbar_effect) THEN
      IF (arg%formul%integration_scheme == UF_Int_Selective) use_bbar_effect = .TRUE.
    END IF

    ! Route to B-bar implementations if needed
    IF (use_bbar_effect) THEN
      SELECT CASE (arg%elem_type%topo)
      CASE (UF_Topo_Hex)
        IF (arg%elem_type%pop%n_nodes == 8) THEN
          CALL Compute_Continuum_C3D8_BBar_Exact(Calc_Continuum_Base, arg%elem_type, arg%formul, &
                                                 arg%ctx, arg%state_in, arg%mat_models, arg%state_out, arg%flags)
          ! Copy error status
          IF (arg%flags%failed) THEN
            arg%status = arg%flags%status
          ELSE
            arg%status%status_code = IF_STATUS_OK
          END IF
          RETURN
        ELSE IF (arg%elem_type%pop%n_nodes == 20) THEN
          CALL Compute_Continuum_C3D20R_BBar_Exact(Calc_Continuum_Base, arg%elem_type, arg%formul, &
                                                   arg%ctx, arg%state_in, arg%mat_models, arg%state_out, arg%flags)
          ! Copy error status
          IF (arg%flags%failed) THEN
            arg%status = arg%flags%status
          ELSE
            arg%status%status_code = IF_STATUS_OK
          END IF
          RETURN
        END IF

      CASE (UF_Topo_Wedge)
        IF (arg%elem_type%pop%n_nodes == 6) THEN
          CALL Compute_Continuum_C3D6_BBar_Exact(Calc_Continuum_Base, arg%elem_type, arg%formul, &
                                                 arg%ctx, arg%state_in, arg%mat_models, arg%state_out, arg%flags)
          ! Copy error status
          IF (arg%flags%failed) THEN
            arg%status = arg%flags%status
          ELSE
            arg%status%status_code = IF_STATUS_OK
          END IF
          RETURN
        ELSE IF (arg%elem_type%pop%n_nodes == 15) THEN
          CALL Compute_Continuum_C3D15_BBar_Exact(Calc_Continuum_Base, arg%elem_type, arg%formul, &
                                                  arg%ctx, arg%state_in, arg%mat_models, arg%state_out, arg%flags)
          ! Copy error status
          IF (arg%flags%failed) THEN
            arg%status = arg%flags%status
          ELSE
            arg%status%status_code = IF_STATUS_OK
          END IF
          RETURN
        END IF
      END SELECT
    END IF

    ! Fallback to base continuum computation
    CALL Calc_Continuum_Base(arg%elem_type, arg%formul, arg%ctx, arg%state_in, arg%mat_models, arg%state_out, arg%flags)
    
    ! Copy error status
    IF (arg%flags%failed) THEN
      arg%status = arg%flags%status
    ELSE
      arg%status%status_code = IF_STATUS_OK
    END IF

  END SUBROUTINE PH_Elem_Contm_Calc3D

  SUBROUTINE PH_Elem_Contm_Calc3D_Structured(arg)
    TYPE(PH_Elem_Contm_Calc3D_Arg), INTENT(INOUT) :: arg
    
    ! Call main interface
    CALL PH_Elem_Contm_Calc3D(arg)
    
  END SUBROUTINE PH_Elem_Contm_Calc3D_Structured

  subroutine UF_Co_ApplyHourglass2D(ElemType, Formul, Ctx, nNode, nDOF, totalVol, props, D, Ke, Re)
    type(UF_ElemType),        intent(in)    :: ElemType
    type(UF_ElemFormul), intent(in)    :: Formul
    type(UF_ElemCtx),     intent(in)    :: Ctx
    integer(i4),                 intent(in)    :: nNode, nDOF
    real(wp),                    intent(in)    :: totalVol
    type(MatProperties),           intent(in)    :: props
    real(wp),                    intent(in)    :: D(6,6)
    real(wp),                    intent(inout) :: Ke(:,:), Re(:)

    real(wp) :: L_char, invL2, dt
    real(wp) :: hg_coeff, hg_visc
    real(wp) :: mu_hg, k_hg
    real(wp) :: gamma4(4,2)
    real(wp) :: q(2)
    real(wp), allocatable :: hourglass_force(:)
    integer(i4) :: iNode, jNode, aDim, m

    logical :: isAxisym

    if (totalVol <= 0.0_wp) return
    if (props%density <= 1.0e-10_wp) return

    dt = Ctx%dTime
    if (dt <= 1.0e-12_wp) return

    if (ElemType%topo /= UF_Topo_Quad .or. nNode /= 4 .or. ElemType%dim /= 2) return

    allocate(hourglass_force(nDOF))
    hourglass_force = 0.0_wp

    isAxisym = (index(ElemType%name, 'CAX') > 0)
    if (isAxisym) then
      L_char = totalVol ** (1.0_wp / 3.0_wp)
    else
      L_char = totalVol ** (1.0_wp / 2.0_wp)
    end if
    invL2  = 1.0_wp / max(L_char*L_char, 1.0e-20_wp)

    gamma4(:,1) = [  1.0_wp, -1.0_wp,  1.0_wp, -1.0_wp ]
    gamma4(:,2) = [  1.0_wp,  1.0_wp, -1.0_wp, -1.0_wp ]

    select case (Formul%hourglass_type)
    case (UF_HG_Viscous)
      hg_coeff = 0.05_wp

      if (allocated(Ctx%disp_pred) .and. Ctx%dyn_a1 > 0.0_wp) then
        hg_visc = hg_coeff * props%density * L_char*L_char
        k_hg    = Ctx%dyn_hht_w * hg_visc * totalVol * Ctx%dyn_a1

        do m = 1, 2
          q = 0.0_wp
          do iNode = 1, 4
            q(1) = q(1) + gamma4(iNode,m) * (Ctx%disp_total(1,iNode) - Ctx%disp_pred(1,iNode))
            q(2) = q(2) + gamma4(iNode,m) * (Ctx%disp_total(2,iNode) - Ctx%disp_pred(2,iNode))
          end do
          q = q * Ctx%dyn_a1

          do iNode = 1, 4
            do aDim = 1, 2
              hourglass_force((iNode-1)*2 + aDim) = hourglass_force((iNode-1)*2 + aDim) + &
                Ctx%dyn_hht_w * hg_visc * totalVol * gamma4(iNode,m) * q(aDim)
            end do
          end do

          do iNode = 1, 4
            do jNode = 1, 4
              do aDim = 1, 2
                Ke((iNode-1)*2 + aDim, (jNode-1)*2 + aDim) = Ke((iNode-1)*2 + aDim, (jNode-1)*2 + aDim) + &
                  k_hg * gamma4(iNode,m) * gamma4(jNode,m)
              end do
            end do
          end do
        end do

        Re(1:2*nNode) = Re(1:2*nNode) + hourglass_force(1:2*nNode)

      else if (allocated(Ctx%disp_incr)) then
        hg_visc = hg_coeff * props%density * L_char*L_char
        k_hg    = hg_visc * totalVol / dt

        do m = 1, 2
          q = 0.0_wp
          do iNode = 1, 4
            q(1) = q(1) + gamma4(iNode,m) * Ctx%disp_incr(1, iNode)
            q(2) = q(2) + gamma4(iNode,m) * Ctx%disp_incr(2, iNode)
          end do
          q = q / dt

          do iNode = 1, 4
            do aDim = 1, 2
              hourglass_force((iNode-1)*2 + aDim) = hourglass_force((iNode-1)*2 + aDim) + &
                hg_visc * totalVol * gamma4(iNode,m) * q(aDim)
            end do
          end do

          do iNode = 1, 4
            do jNode = 1, 4
              do aDim = 1, 2
                Ke((iNode-1)*2 + aDim, (jNode-1)*2 + aDim) = Ke((iNode-1)*2 + aDim, (jNode-1)*2 + aDim) + &
                  k_hg * gamma4(iNode,m) * gamma4(jNode,m)
              end do
            end do
          end do
        end do

        Re(1:2*nNode) = Re(1:2*nNode) + hourglass_force(1:2*nNode)
      end if

    case (UF_HG_Flanagan, UF_HG_Enhanced)
      hg_coeff = 0.10_wp

      mu_hg = 0.0_wp
      if (abs(D(4,4)) > 1.0e-16_wp) mu_hg = abs(D(4,4))
      if (mu_hg <= 0.0_wp) then
        if (allocated(props%props) .and. size(props%props) >= 2) then
          mu_hg = props%props(1) / max(2.0_wp * (1.0_wp + props%props(2)), 1.0e-12_wp)
        end if
      end if

      if (mu_hg > 0.0_wp) then
        k_hg = hg_coeff * mu_hg * totalVol * invL2

        do m = 1, 2
          q = 0.0_wp
          do iNode = 1, 4
            q(1) = q(1) + gamma4(iNode,m) * Ctx%disp_total(1, iNode)
            q(2) = q(2) + gamma4(iNode,m) * Ctx%disp_total(2, iNode)
          end do

          do iNode = 1, 4
            do aDim = 1, 2
              Re((iNode-1)*2 + aDim) = Re((iNode-1)*2 + aDim) + k_hg * gamma4(iNode,m) * q(aDim)
            end do
          end do

          do iNode = 1, 4
            do jNode = 1, 4
              do aDim = 1, 2
                Ke((iNode-1)*2 + aDim, (jNode-1)*2 + aDim) = Ke((iNode-1)*2 + aDim, (jNode-1)*2 + aDim) + &
                  k_hg * gamma4(iNode,m) * gamma4(jNode,m)
              end do
            end do
          end do
        end do
      end if

    case default
      continue
    end select

    if (allocated(hourglass_force)) deallocate(hourglass_force)

  end subroutine UF_Continuum_ApplyHourglass2D

  subroutine UF_Co_ApplyHourglass2D(ElemType, Formul, Ctx, nNode, nDOF, totalVol, props, D, Ke, Re)
    type(UF_ElemType),        intent(in)    :: ElemType
    type(UF_ElemFormul), intent(in)    :: Formul
    type(UF_ElemCtx),     intent(in)    :: Ctx
    integer(i4),                 intent(in)    :: nNode, nDOF
    real(wp),                    intent(in)    :: totalVol
    type(MatProperties),           intent(in)    :: props
    real(wp),                    intent(in)    :: D(6,6)
    real(wp),                    intent(inout) :: Ke(:,:), Re(:)

    real(wp) :: L_char, invL2, dt
    real(wp) :: hg_coeff, hg_visc
    real(wp) :: mu_hg, k_hg
    real(wp) :: gamma4(4,2)
    real(wp) :: q(2)
    real(wp), allocatable :: hourglass_force(:)
    integer(i4) :: iNode, jNode, aDim, m

    logical :: isAxisym

    if (totalVol <= 0.0_wp) return
    if (props%density <= 1.0e-10_wp) return

    dt = Ctx%dTime
    if (dt <= 1.0e-12_wp) return

    if (ElemType%topo /= UF_Topo_Quad .or. nNode /= 4 .or. ElemType%dim /= 2) return

    allocate(hourglass_force(nDOF))
    hourglass_force = 0.0_wp

    isAxisym = (index(ElemType%name, 'CAX') > 0)
    if (isAxisym) then
      L_char = totalVol ** (1.0_wp / 3.0_wp)
    else
      L_char = totalVol ** (1.0_wp / 2.0_wp)
    end if
    invL2  = 1.0_wp / max(L_char*L_char, 1.0e-20_wp)

    gamma4(:,1) = [  1.0_wp, -1.0_wp,  1.0_wp, -1.0_wp ]
    gamma4(:,2) = [  1.0_wp,  1.0_wp, -1.0_wp, -1.0_wp ]

    select case (Formul%hourglass_type)
    case (UF_HG_Viscous)
      hg_coeff = 0.05_wp

      if (allocated(Ctx%disp_pred) .and. Ctx%dyn_a1 > 0.0_wp) then
        hg_visc = hg_coeff * props%density * L_char*L_char
        k_hg    = Ctx%dyn_hht_w * hg_visc * totalVol * Ctx%dyn_a1

        do m = 1, 2
          q = 0.0_wp
          do iNode = 1, 4
            q(1) = q(1) + gamma4(iNode,m) * (Ctx%disp_total(1,iNode) - Ctx%disp_pred(1,iNode))
            q(2) = q(2) + gamma4(iNode,m) * (Ctx%disp_total(2,iNode) - Ctx%disp_pred(2,iNode))
          end do
          q = q * Ctx%dyn_a1

          do iNode = 1, 4
            do aDim = 1, 2
              hourglass_force((iNode-1)*2 + aDim) = hourglass_force((iNode-1)*2 + aDim) + &
                Ctx%dyn_hht_w * hg_visc * totalVol * gamma4(iNode,m) * q(aDim)
            end do
          end do

          do iNode = 1, 4
            do jNode = 1, 4
              do aDim = 1, 2
                Ke((iNode-1)*2 + aDim, (jNode-1)*2 + aDim) = Ke((iNode-1)*2 + aDim, (jNode-1)*2 + aDim) + &
                  k_hg * gamma4(iNode,m) * gamma4(jNode,m)
              end do
            end do
          end do
        end do

        Re(1:2*nNode) = Re(1:2*nNode) + hourglass_force(1:2*nNode)

      else if (allocated(Ctx%disp_incr)) then
        hg_visc = hg_coeff * props%density * L_char*L_char
        k_hg    = hg_visc * totalVol / dt

        do m = 1, 2
          q = 0.0_wp
          do iNode = 1, 4
            q(1) = q(1) + gamma4(iNode,m) * Ctx%disp_incr(1, iNode)
            q(2) = q(2) + gamma4(iNode,m) * Ctx%disp_incr(2, iNode)
          end do
          q = q / dt

          do iNode = 1, 4
            do aDim = 1, 2
              hourglass_force((iNode-1)*2 + aDim) = hourglass_force((iNode-1)*2 + aDim) + &
                hg_visc * totalVol * gamma4(iNode,m) * q(aDim)
            end do
          end do

          do iNode = 1, 4
            do jNode = 1, 4
              do aDim = 1, 2
                Ke((iNode-1)*2 + aDim, (jNode-1)*2 + aDim) = Ke((iNode-1)*2 + aDim, (jNode-1)*2 + aDim) + &
                  k_hg * gamma4(iNode,m) * gamma4(jNode,m)
              end do
            end do
          end do
        end do

        Re(1:2*nNode) = Re(1:2*nNode) + hourglass_force(1:2*nNode)
      end if

    case (UF_HG_Flanagan, UF_HG_Enhanced)
      hg_coeff = 0.10_wp

      mu_hg = 0.0_wp
      if (abs(D(4,4)) > 1.0e-16_wp) mu_hg = abs(D(4,4))
      if (mu_hg <= 0.0_wp) then
        if (allocated(props%props) .and. size(props%props) >= 2) then
          mu_hg = props%props(1) / max(2.0_wp * (1.0_wp + props%props(2)), 1.0e-12_wp)
        end if
      end if

      if (mu_hg > 0.0_wp) then
        k_hg = hg_coeff * mu_hg * totalVol * invL2

        do m = 1, 2
          q = 0.0_wp
          do iNode = 1, 4
            q(1) = q(1) + gamma4(iNode,m) * Ctx%disp_total(1, iNode)
            q(2) = q(2) + gamma4(iNode,m) * Ctx%disp_total(2, iNode)
          end do

          do iNode = 1, 4
            do aDim = 1, 2
              Re((iNode-1)*2 + aDim) = Re((iNode-1)*2 + aDim) + k_hg * gamma4(iNode,m) * q(aDim)
            end do
          end do

          do iNode = 1, 4
            do jNode = 1, 4
              do aDim = 1, 2
                Ke((iNode-1)*2 + aDim, (jNode-1)*2 + aDim) = Ke((iNode-1)*2 + aDim, (jNode-1)*2 + aDim) + &
                  k_hg * gamma4(iNode,m) * gamma4(jNode,m)
              end do
            end do
          end do
        end do
      end if

    case default
      continue
    end select

    if (allocated(hourglass_force)) deallocate(hourglass_force)

  end subroutine UF_Continuum_ApplyHourglass2D

  subroutine UF_Co_ApplyHourglass3D(ElemType, Formul, Ctx, nNode, nDOF, totalVol, props, D, Ke, Re)
    type(UF_ElemType),        intent(in)    :: ElemType
    type(UF_ElemFormul), intent(in)    :: Formul
    type(UF_ElemCtx),     intent(in)    :: Ctx
    integer(i4),                 intent(in)    :: nNode, nDOF
    real(wp),                    intent(in)    :: totalVol
    type(MatProperties),           intent(in)    :: props
    real(wp),                    intent(in)    :: D(6,6)
    real(wp),                    intent(inout) :: Ke(:,:), Re(:)

    real(wp) :: L_char, invL2, dt
    real(wp) :: hg_coeff, hg_visc
    real(wp) :: mu_hg, k_hg
    real(wp) :: gamma8(8,4)
    real(wp) :: q(3)
    real(wp), allocatable :: hourglass_force(:)
    integer(i4) :: iNode, jNode, aDim, m

    if (totalVol <= 0.0_wp) return
    if (props%density <= 1.0e-10_wp) return

    dt = Ctx%dTime
    if (dt <= 1.0e-12_wp) return

    if (ElemType%topo /= UF_Topo_Hex .or. nNode /= 8 .or. ElemType%dim /= 3) return

    allocate(hourglass_force(nDOF))
    hourglass_force = 0.0_wp

    L_char = totalVol ** (1.0_wp / 3.0_wp)
    invL2  = 1.0_wp / max(L_char*L_char, 1.0e-20_wp)

    gamma8(:,1) = [  1.0_wp, -1.0_wp,  1.0_wp, -1.0_wp, -1.0_wp,  1.0_wp, -1.0_wp,  1.0_wp ]
    gamma8(:,2) = [  1.0_wp,  1.0_wp, -1.0_wp, -1.0_wp, -1.0_wp, -1.0_wp,  1.0_wp,  1.0_wp ]
    gamma8(:,3) = [  1.0_wp, -1.0_wp, -1.0_wp,  1.0_wp, -1.0_wp,  1.0_wp,  1.0_wp, -1.0_wp ]
    gamma8(:,4) = [  1.0_wp,  1.0_wp,  1.0_wp,  1.0_wp, -1.0_wp, -1.0_wp, -1.0_wp, -1.0_wp ]

    select case (Formul%hourglass_type)
    case (UF_HG_Viscous)
      hg_coeff = 0.05_wp

      if (allocated(Ctx%disp_pred) .and. Ctx%dyn_a1 > 0.0_wp) then
        hg_visc = hg_coeff * props%density * L_char*L_char
        k_hg    = Ctx%dyn_hht_w * hg_visc * totalVol * Ctx%dyn_a1

        do m = 1, 4
          q = 0.0_wp
          do iNode = 1, 8
            q(1) = q(1) + gamma8(iNode,m) * (Ctx%disp_total(1,iNode) - Ctx%disp_pred(1,iNode))
            q(2) = q(2) + gamma8(iNode,m) * (Ctx%disp_total(2,iNode) - Ctx%disp_pred(2,iNode))
            q(3) = q(3) + gamma8(iNode,m) * (Ctx%disp_total(3,iNode) - Ctx%disp_pred(3,iNode))
          end do
          q = q * Ctx%dyn_a1

          do iNode = 1, 8
            do aDim = 1, 3
              hourglass_force((iNode-1)*3 + aDim) = hourglass_force((iNode-1)*3 + aDim) + &
                Ctx%dyn_hht_w * hg_visc * totalVol * gamma8(iNode,m) * q(aDim)
            end do
          end do

          do iNode = 1, 8
            do jNode = 1, 8
              do aDim = 1, 3
                Ke((iNode-1)*3 + aDim, (jNode-1)*3 + aDim) = Ke((iNode-1)*3 + aDim, (jNode-1)*3 + aDim) + &
                  k_hg * gamma8(iNode,m) * gamma8(jNode,m)
              end do
            end do
          end do
        end do

        Re(1:3*nNode) = Re(1:3*nNode) + hourglass_force(1:3*nNode)

      else if (allocated(Ctx%disp_incr)) then
        hg_visc = hg_coeff * props%density * L_char*L_char
        k_hg    = hg_visc * totalVol / dt

        do m = 1, 4
          q = 0.0_wp
          do iNode = 1, 8
            q(1) = q(1) + gamma8(iNode,m) * Ctx%disp_incr(1, iNode)
            q(2) = q(2) + gamma8(iNode,m) * Ctx%disp_incr(2, iNode)
            q(3) = q(3) + gamma8(iNode,m) * Ctx%disp_incr(3, iNode)
          end do
          q = q / dt

          do iNode = 1, 8
            do aDim = 1, 3
              hourglass_force((iNode-1)*3 + aDim) = hourglass_force((iNode-1)*3 + aDim) + &
                hg_visc * totalVol * gamma8(iNode,m) * q(aDim)
            end do
          end do

          do iNode = 1, 8
            do jNode = 1, 8
              do aDim = 1, 3
                Ke((iNode-1)*3 + aDim, (jNode-1)*3 + aDim) = Ke((iNode-1)*3 + aDim, (jNode-1)*3 + aDim) + &
                  k_hg * gamma8(iNode,m) * gamma8(jNode,m)
              end do
            end do
          end do
        end do

        Re(1:3*nNode) = Re(1:3*nNode) + hourglass_force(1:3*nNode)
      end if

    case (UF_HG_Flanagan, UF_HG_Enhanced)
      hg_coeff = 0.10_wp

      mu_hg = 0.0_wp
      if (abs(D(4,4)) > 1.0e-16_wp) mu_hg = abs(D(4,4))
      if (mu_hg <= 0.0_wp) then
        if (allocated(props%props) .and. size(props%props) >= 2) then
          mu_hg = props%props(1) / max(2.0_wp * (1.0_wp + props%props(2)), 1.0e-12_wp)
        end if
      end if

      if (mu_hg > 0.0_wp) then
        k_hg = hg_coeff * mu_hg * totalVol * invL2

        do m = 1, 4
          q = 0.0_wp
          do iNode = 1, 8
            q(1) = q(1) + gamma8(iNode,m) * Ctx%disp_total(1, iNode)
            q(2) = q(2) + gamma8(iNode,m) * Ctx%disp_total(2, iNode)
            q(3) = q(3) + gamma8(iNode,m) * Ctx%disp_total(3, iNode)
          end do

          do iNode = 1, 8
            do aDim = 1, 3
              Re((iNode-1)*3 + aDim) = Re((iNode-1)*3 + aDim) + k_hg * gamma8(iNode,m) * q(aDim)
            end do
          end do

          do iNode = 1, 8
            do jNode = 1, 8
              do aDim = 1, 3
                Ke((iNode-1)*3 + aDim, (jNode-1)*3 + aDim) = Ke((iNode-1)*3 + aDim, (jNode-1)*3 + aDim) + &
                  k_hg * gamma8(iNode,m) * gamma8(jNode,m)
              end do
            end do
          end do
        end do
      end if

    case default
      continue
    end select

    if (allocated(hourglass_force)) deallocate(hourglass_force)

  end subroutine UF_Continuum_ApplyHourglass3D

  subroutine UF_Co_ApplyHourglass3D(ElemType, Formul, Ctx, nNode, nDOF, totalVol, props, D, Ke, Re)
    type(UF_ElemType),        intent(in)    :: ElemType
    type(UF_ElemFormul), intent(in)    :: Formul
    type(UF_ElemCtx),     intent(in)    :: Ctx
    integer(i4),                 intent(in)    :: nNode, nDOF
    real(wp),                    intent(in)    :: totalVol
    type(MatProperties),           intent(in)    :: props
    real(wp),                    intent(in)    :: D(6,6)
    real(wp),                    intent(inout) :: Ke(:,:), Re(:)

    real(wp) :: L_char, invL2, dt
    real(wp) :: hg_coeff, hg_visc
    real(wp) :: mu_hg, k_hg
    real(wp) :: gamma8(8,4)
    real(wp) :: q(3)
    real(wp), allocatable :: hourglass_force(:)
    integer(i4) :: iNode, jNode, aDim, m

    if (totalVol <= 0.0_wp) return
    if (props%density <= 1.0e-10_wp) return

    dt = Ctx%dTime
    if (dt <= 1.0e-12_wp) return

    if (ElemType%topo /= UF_Topo_Hex .or. nNode /= 8 .or. ElemType%dim /= 3) return

    allocate(hourglass_force(nDOF))
    hourglass_force = 0.0_wp

    L_char = totalVol ** (1.0_wp / 3.0_wp)
    invL2  = 1.0_wp / max(L_char*L_char, 1.0e-20_wp)

    gamma8(:,1) = [  1.0_wp, -1.0_wp,  1.0_wp, -1.0_wp, -1.0_wp,  1.0_wp, -1.0_wp,  1.0_wp ]
    gamma8(:,2) = [  1.0_wp,  1.0_wp, -1.0_wp, -1.0_wp, -1.0_wp, -1.0_wp,  1.0_wp,  1.0_wp ]
    gamma8(:,3) = [  1.0_wp, -1.0_wp, -1.0_wp,  1.0_wp, -1.0_wp,  1.0_wp,  1.0_wp, -1.0_wp ]
    gamma8(:,4) = [  1.0_wp,  1.0_wp,  1.0_wp,  1.0_wp, -1.0_wp, -1.0_wp, -1.0_wp, -1.0_wp ]

    select case (Formul%hourglass_type)
    case (UF_HG_Viscous)
      hg_coeff = 0.05_wp

      if (allocated(Ctx%disp_pred) .and. Ctx%dyn_a1 > 0.0_wp) then
        hg_visc = hg_coeff * props%density * L_char*L_char
        k_hg    = Ctx%dyn_hht_w * hg_visc * totalVol * Ctx%dyn_a1

        do m = 1, 4
          q = 0.0_wp
          do iNode = 1, 8
            q(1) = q(1) + gamma8(iNode,m) * (Ctx%disp_total(1,iNode) - Ctx%disp_pred(1,iNode))
            q(2) = q(2) + gamma8(iNode,m) * (Ctx%disp_total(2,iNode) - Ctx%disp_pred(2,iNode))
            q(3) = q(3) + gamma8(iNode,m) * (Ctx%disp_total(3,iNode) - Ctx%disp_pred(3,iNode))
          end do
          q = q * Ctx%dyn_a1

          do iNode = 1, 8
            do aDim = 1, 3
              hourglass_force((iNode-1)*3 + aDim) = hourglass_force((iNode-1)*3 + aDim) + &
                Ctx%dyn_hht_w * hg_visc * totalVol * gamma8(iNode,m) * q(aDim)
            end do
          end do

          do iNode = 1, 8
            do jNode = 1, 8
              do aDim = 1, 3
                Ke((iNode-1)*3 + aDim, (jNode-1)*3 + aDim) = Ke((iNode-1)*3 + aDim, (jNode-1)*3 + aDim) + &
                  k_hg * gamma8(iNode,m) * gamma8(jNode,m)
              end do
            end do
          end do
        end do

        Re(1:3*nNode) = Re(1:3*nNode) + hourglass_force(1:3*nNode)

      else if (allocated(Ctx%disp_incr)) then
        hg_visc = hg_coeff * props%density * L_char*L_char
        k_hg    = hg_visc * totalVol / dt

        do m = 1, 4
          q = 0.0_wp
          do iNode = 1, 8
            q(1) = q(1) + gamma8(iNode,m) * Ctx%disp_incr(1, iNode)
            q(2) = q(2) + gamma8(iNode,m) * Ctx%disp_incr(2, iNode)
            q(3) = q(3) + gamma8(iNode,m) * Ctx%disp_incr(3, iNode)
          end do
          q = q / dt

          do iNode = 1, 8
            do aDim = 1, 3
              hourglass_force((iNode-1)*3 + aDim) = hourglass_force((iNode-1)*3 + aDim) + &
                hg_visc * totalVol * gamma8(iNode,m) * q(aDim)
            end do
          end do

          do iNode = 1, 8
            do jNode = 1, 8
              do aDim = 1, 3
                Ke((iNode-1)*3 + aDim, (jNode-1)*3 + aDim) = Ke((iNode-1)*3 + aDim, (jNode-1)*3 + aDim) + &
                  k_hg * gamma8(iNode,m) * gamma8(jNode,m)
              end do
            end do
          end do
        end do

        Re(1:3*nNode) = Re(1:3*nNode) + hourglass_force(1:3*nNode)
      end if

    case (UF_HG_Flanagan, UF_HG_Enhanced)
      hg_coeff = 0.10_wp

      mu_hg = 0.0_wp
      if (abs(D(4,4)) > 1.0e-16_wp) mu_hg = abs(D(4,4))
      if (mu_hg <= 0.0_wp) then
        if (allocated(props%props) .and. size(props%props) >= 2) then
          mu_hg = props%props(1) / max(2.0_wp * (1.0_wp + props%props(2)), 1.0e-12_wp)
        end if
      end if

      if (mu_hg > 0.0_wp) then
        k_hg = hg_coeff * mu_hg * totalVol * invL2

        do m = 1, 4
          q = 0.0_wp
          do iNode = 1, 8
            q(1) = q(1) + gamma8(iNode,m) * Ctx%disp_total(1, iNode)
            q(2) = q(2) + gamma8(iNode,m) * Ctx%disp_total(2, iNode)
            q(3) = q(3) + gamma8(iNode,m) * Ctx%disp_total(3, iNode)
          end do

          do iNode = 1, 8
            do aDim = 1, 3
              Re((iNode-1)*3 + aDim) = Re((iNode-1)*3 + aDim) + k_hg * gamma8(iNode,m) * q(aDim)
            end do
          end do

          do iNode = 1, 8
            do jNode = 1, 8
              do aDim = 1, 3
                Ke((iNode-1)*3 + aDim, (jNode-1)*3 + aDim) = Ke((iNode-1)*3 + aDim, (jNode-1)*3 + aDim) + &
                  k_hg * gamma8(iNode,m) * gamma8(jNode,m)
              end do
            end do
          end do
        end do
      end if

    case default
      continue
    end select

    if (allocated(hourglass_force)) deallocate(hourglass_force)

  end subroutine UF_Continuum_ApplyHourglass3D

  subroutine UF_Continuum_AllocWork(nDOF, Ke, Re, Me, Ce, B)
    integer(i4), intent(in) :: nDOF
    real(wp), pointer, intent(out) :: Ke(:,:), Re(:)
    real(wp), pointer, intent(out) :: Me(:,:), Ce(:,:)
    real(wp), pointer, intent(out) :: B(:,:)

    ! Workspace allocation delegated to UF_WorkspaceManager
    !   - grow-only strategy (realloc only when capacity insufficient)
    !   - all structural continuum elements share one pooled buffer

    call GetStructWS(nDOF, Ke, Re, Me, Ce, B)
  end subroutine UF_Continuum_AllocWork

  subroutine UF_Continuum_ApplyHourglass(ElemType, Formul, Ctx, nNode, nDim, nDOF, isAxisym, totalVol, props, D, Ke, Re)
    type(ElemType),       intent(in)    :: ElemType
    type(ElemFormul), intent(in)    :: Formul
    type(ElemCtx),    intent(in)    :: Ctx
    integer(i4),                 intent(in)    :: nNode, nDim, nDOF
    logical,                     intent(in)    :: isAxisym
    real(wp),                    intent(in)    :: totalVol
    type(MatProperties),           intent(in)    :: props
    real(wp),                    intent(in)    :: D(6,6)
    real(wp),                    intent(inout) :: Ke(:,:), Re(:)

    ! Facade: 3D Hex8R uses 3D Hourglass; 2D QuadR/AXI uses 2D version
    if (nDim == 3 .and. .not. isAxisym) then
      call UF_Continuum_ApplyHourglass3D(ElemType, Formul, Ctx, nNode, nDOF, totalVol, props, D, Ke, Re)
    else
      call UF_Continuum_ApplyHourglass2D(ElemType, Formul, Ctx, nNode, nDOF, totalVol, props, D, Ke, Re)
    end if

  end subroutine UF_Continuum_ApplyHourglass

  subroutine UF_Continuum_EstimateStblDt(elemName, nDim, isAxisym, totalVol, props, stableDt)
    character(len=*), intent(in)  :: elemName
    integer(i4),      intent(in)  :: nDim
    logical,          intent(in)  :: isAxisym
    real(wp),         intent(in)  :: totalVol
    type(MatProperties),intent(in)  :: props
    real(wp),         intent(inout) :: stableDt

    real(wp) :: E, nu, denom
    real(wp) :: wave_speed
    real(wp) :: L_char

    if (totalVol <= 0.0_wp) return
    if (props%density <= 1.0e-10_wp) return
    if (.not. allocated(props%props)) return
    if (size(props%props) < UF_MAT_PROP_ELA) return

    E  = props%props(UF_MAT_PROP_ELA)
    nu = props%props(UF_MAT_PROP_ELA)

    denom = (1.0_wp + nu) * max(1.0e-10_wp, (1.0_wp - 2.0_wp*nu))
    wave_speed = 0.0_wp

    if (nDim == 3 .and. .not. isAxisym) then
      wave_speed = sqrt(E / (denom * props%density))
    else
      if (index(elemName, 'CPS') > 0) then
        wave_speed = sqrt(E / (denom * props%density))
      else
        wave_speed = sqrt(E * (1.0_wp - nu) / (denom * props%density))
      end if
    end if

    if (wave_speed > 1.0e-16_wp) then
      L_char = totalVol ** (1.0_wp / real(nDim, wp))
      stableDt = L_char / wave_speed
    end if

  end subroutine UF_Continuum_EstimateStableDt

  subroutine UF_Continuum_WriteBackState(state_out, Ke, Re, Me, Ce, nDOF)
    type(ElemState), intent(inout) :: state_out
    integer(i4),           intent(in)    :: nDOF
    real(wp),              intent(in)    :: Ke(:,:), Re(:)
    real(wp),              intent(in)    :: Me(:,:), Ce(:,:)

    ! Assume external orchestration already allocated Ke/Re/Me/Ce; here only copy data

    state_out%evo%Ke(1:nDOF,1:nDOF) = Ke(1:nDOF,1:nDOF)
    state_out%Re(1:nDOF)        = Re(1:nDOF)
    state_out%Me(1:nDOF,1:nDOF) = Me(1:nDOF,1:nDOF)
    state_out%Ce(1:nDOF,1:nDOF) = Ce(1:nDOF,1:nDOF)

  end subroutine UF_Continuum_WriteBackState

  subroutine UF_Embed_StructBlock(nNode, ndpn_struct, ndpn_total, &
                                 Ke_full, Re_full, Me_full, Ce_full, &
                                 Ke_u, Re_u, Me_u, Ce_u)
    integer(i4), intent(in) :: nNode, ndpn_struct, ndpn_total
    real(wp),   intent(inout) :: Ke_full(:,:), Re_full(:)
    real(wp),   intent(inout) :: Me_full(:,:), Ce_full(:,:)
    real(wp),   intent(in)    :: Ke_u(:,:), Re_u(:)
    real(wp),   intent(in)    :: Me_u(:,:), Ce_u(:,:)

    integer(i4) :: iNode, jNode, a, b
    integer(i4) :: row_u, col_u, row_full, col_full

    do iNode = 1, nNode
      do a = 1, ndpn_struct
        row_u    = (iNode-1)*ndpn_struct + a
        row_full = (iNode-1)*ndpn_total  + a

        ! Internal force: scatter structural Re_u into full Re_full U-block

        if (row_full >= 1 .and. row_full <= size(Re_full)) then
          Re_full(row_full) = Re_full(row_full) + Re_u(row_u)
        end if

        ! Mass: embed Me_u into full Me_full U-U block

        if (size(Me_full,1) > 0 .and. size(Me_full,2) > 0) then
          do jNode = 1, nNode
            do b = 1, ndpn_struct
              col_u    = (jNode-1)*ndpn_struct + b
              col_full = (jNode-1)*ndpn_total  + b
              if (col_full < 1 .or. col_full > size(Me_full,2)) cycle
              Me_full(row_full, col_full) = Me_full(row_full, col_full) + Me_u(row_u, col_u)
            end do
          end do
        end if

        ! Damping/conductivity: embed Ce_u into full Ce_full U-U block

        if (size(Ce_full,1) > 0 .and. size(Ce_full,2) > 0) then
          do jNode = 1, nNode
            do b = 1, ndpn_struct
              col_u    = (jNode-1)*ndpn_struct + b
              col_full = (jNode-1)*ndpn_total  + b
              if (col_full < 1 .or. col_full > size(Ce_full,2)) cycle
              Ce_full(row_full, col_full) = Ce_full(row_full, col_full) + Ce_u(row_u, col_u)
            end do
          end do
        end if

        ! Stiffness: embed Kuu into Ke_full structural block

        do jNode = 1, nNode
          do b = 1, ndpn_struct
            col_u    = (jNode-1)*ndpn_struct + b
            col_full = (jNode-1)*ndpn_total  + b
            if (col_full < 1 .or. col_full > size(Ke_full,2)) cycle
            Ke_full(row_full, col_full) = Ke_full(row_full, col_full) + Ke_u(row_u, col_u)
          end do
        end do
      end do
    end do

  end subroutine UF_Embed_StructBlock

  subroutine UF_Init_Continuum(Element, name)
    type(ElemType), intent(inout) :: Element
    character(len=*), intent(in)        :: name

    ! Check if this is a Porous (P) element - route to UF_Init_Continuum_Poro
    if (len_trim(name) >= 1 .and. name(len_trim(name):len_trim(name)) == 'P') then
      call UF_Init_Continuum_Poro(Element, name)
      return
    end if

    ! Facade: Dispatch initialization to 3D/2D version based on name prefix
    if (index(name, 'C3D') == 1 .or. index(name, 'DC3D') == 1) then
      call UF_Init_Continuum3D(Element, name)
    else
      call UF_Init_Continuum2D(Element, name)
    end if

    ! Point compute to Facade version
    Element%compute => Calc_Continuum

  end subroutine UF_Init_Continuum

  subroutine UF_Init_Continuum2D(Element, name)
    type(UF_ElemType), intent(inout) :: Element
    character(len=*),     intent(in)    :: name

    Element%name   = name
    Element%family = UF_FAMILY_CONTI
    Element%n_dof_per_node = 2

    select case (trim(name))
    ! --- 2D Quad (PS/PE/AXI) ---
    case ('CPE4', 'CPS4', 'CAX4', 'CPE4T', 'CPS4T', 'CAX4T', 'CPE4P', 'CPS4P', 'CAX4P')
      Element%pop%n_nodes      = 4
      Element%dim        = 2
      Element%topo = UF_Topo_Quad
      Element%n_int_points = 4

    case ('CPE4R', 'CPS4R', 'CAX4R')
      Element%pop%n_nodes      = 4
      Element%dim        = 2
      Element%topo = UF_Topo_Quad
      Element%n_int_points = 1

    case ('CPE8', 'CPS8', 'CAX8', 'CPE8T', 'CPS8T', 'CAX8T', 'CPE8P', 'CPS8P', 'CAX8P')
      Element%pop%n_nodes      = 8
      Element%dim        = 2
      Element%topo = UF_Topo_Quad
      Element%n_int_points = 9

    case ('CPE8R', 'CPS8R', 'CAX8R')
      Element%pop%n_nodes      = 8
      Element%dim        = 2
      Element%topo = UF_Topo_Quad
      Element%n_int_points = 4

    ! --- 2D Tri ---
    case ('CPE3', 'CPS3', 'CAX3', 'CPE3P', 'CPS3P', 'CAX3P')
      Element%pop%n_nodes      = 3
      Element%dim        = 2
      Element%topo = UF_Topo_Tri
      Element%n_int_points = 3

    case ('CPE6', 'CPS6', 'CAX6', 'CPE6P', 'CPS6P', 'CAX6P')
      Element%pop%n_nodes      = 6
      Element%dim        = 2
      Element%topo = UF_Topo_Tri
      Element%n_int_points = 3

    ! --- Additional 2D element types ---
    case ('CPE4H', 'CPS4H', 'CAX4H')  ! Hybrid Formul
      Element%pop%n_nodes      = 4
      Element%dim        = 2
      Element%topo = UF_Topo_Quad
      Element%n_int_points = 4
      Element%defaultFormul%use_bbar = .true.

    case ('CPE3H', 'CPS3H', 'CAX3H')  ! Hybrid triangle
      Element%pop%n_nodes      = 3
      Element%dim        = 2
      Element%topo = UF_Topo_Tri
      Element%n_int_points = 3
      Element%defaultFormul%use_bbar = .true.

    case default
      Element%pop%n_nodes      = 4
      Element%dim        = 2
      Element%topo = UF_Topo_Quad
      Element%n_int_points = 4
    end select

    Element%defaultFormul%integration_scheme = UF_Int_Full
    if (index(name, 'R') > 0) Element%defaultFormul%integration_scheme = UF_Int_Reduced

    Element%has_struct  = .true.
    Element%has_thermal = .false.
    Element%has_pore    = .false.

  end subroutine UF_Init_Continuum2D


  subroutine UF_Init_Continuum3D(Element, name)
    type(UF_ElemType), intent(inout) :: Element
    character(len=*),     intent(in)    :: name

    Element%name   = name
    Element%family = UF_FAMILY_CONTI
    Element%n_dof_per_node = 3

    select case (trim(name))
    ! --- 3D Hex ---
    case ('C3D8', 'C3D8I', 'C3D8H', 'C3D8T', 'C3D8P')
      Element%pop%n_nodes      = 8
      Element%dim        = 3
      Element%topo = UF_Topo_Hex
      Element%n_int_points = 8

    case ('C3D8R')
      Element%pop%n_nodes      = 8
      Element%dim        = 3
      Element%topo = UF_Topo_Hex
      Element%n_int_points = 1

    case ('C3D20', 'C3D20H', 'C3D20T', 'C3D20P')
      Element%pop%n_nodes      = 20
      Element%dim        = 3
      Element%topo = UF_Topo_Hex
      Element%n_int_points = 27

    case ('C3D20R')
      Element%pop%n_nodes      = 20
      Element%dim        = 3
      Element%topo = UF_Topo_Hex
      Element%n_int_points = 8

    case ('C3D27', 'C3D27P')
      Element%pop%n_nodes      = 27
      Element%dim        = 3
      Element%topo = UF_Topo_Hex
      Element%n_int_points = 27

    ! --- 3D Tet ---
    case ('C3D4', 'DC3D4', 'C3D4P')
      Element%pop%n_nodes      = 4
      Element%dim        = 3
      Element%topo = UF_Topo_Tet
      Element%n_int_points = 1
      if (name(1:2) == 'DC') Element%n_dof_per_node = 1

    case ('C3D10', 'C3D10M', 'C3D10P')
      Element%pop%n_nodes      = 10
      Element%dim        = 3
      Element%topo = UF_Topo_Tet
      Element%n_int_points = 4

    ! --- 3D Wedge ---
    case ('C3D6', 'DC3D6', 'C3D6P')
      Element%pop%n_nodes      = 6
      Element%dim        = 3
      Element%topo = UF_Topo_Wedge
      Element%n_int_points = 6

    case ('C3D15', 'C3D15P')
      Element%pop%n_nodes      = 15
      Element%dim        = 3
      Element%topo = UF_Topo_Wedge
      Element%n_int_points = 9

    ! --- Additional 3D element types ---
    case ('C3D8H')  ! Hybrid Formul
      Element%pop%n_nodes      = 8
      Element%dim        = 3
      Element%topo = UF_Topo_Hex
      Element%n_int_points = 8
      Element%defaultFormul%use_bbar = .true.

    case ('C3D10H')  ! Hybrid tetrahedron
      Element%pop%n_nodes      = 10
      Element%dim        = 3
      Element%topo = UF_Topo_Tet
      Element%n_int_points = 4
      Element%defaultFormul%use_bbar = .true.

    case default
      Element%pop%n_nodes      = 8
      Element%dim        = 3
      Element%topo = UF_Topo_Hex
      Element%n_int_points = 8
    end select

    Element%defaultFormul%integration_scheme = UF_Int_Full
    if (index(name, 'R') > 0) Element%defaultFormul%integration_scheme = UF_Int_Reduced

    Element%has_struct  = .true.
    Element%has_thermal = (name(1:2) == 'DC')
    Element%has_pore    = .false.

  end subroutine UF_Init_Continuum3D


  subroutine UF_Init_Continuum_Poro(Element, name)
    type(ElemType), intent(inout) :: Element
    character(len=*),     intent(in)    :: name

    character(len=len(name)) :: baseName
    integer(i4) :: L

    baseName = trim(name)
    L = len_trim(baseName)

    if (L >= 2 .and. baseName(L-1:L) == 'PT') then
      baseName = baseName(1:L-2)
    else if (L >= 1 .and. (baseName(L:L) == 'T' .or. baseName(L:L) == 'P')) then
      baseName = baseName(1:L-1)
    end if

    call UF_Init_Continuum(Element, baseName)

    Element%name = trim(name)
    Element%compute => Calc_Continuum_Poro

    if (Element%dim == 3) then
      Element%n_dof_per_node = 4
    else
      Element%n_dof_per_node = 3
    end if

    Element%has_struct   = .true.
    Element%has_thermal  = .false.
    Element%has_pore     = .true.
  end subroutine UF_Init_Continuum_Poro

  subroutine UF_Init_Continuum_Thermal(Element, name)
    type(ElemType), intent(inout) :: Element
    character(len=*),     intent(in)    :: name

    character(len=len(name)) :: baseName
    integer(i4) :: L

    baseName = trim(name)
    L = len_trim(baseName)
    if (L >= 2 .and. baseName(L-1:L) == 'PT') then
      baseName = baseName(1:L-2)
    else if (L >= 1 .and. (baseName(L:L) == 'T' .or. baseName(L:L) == 'P')) then
      baseName = baseName(1:L-1)
    end if

    call UF_Init_Continuum(Element, baseName)
    Element%name = trim(name)
    Element%compute => Calc_Continuum_Thermal

    if (Element%dim == 3) then
      Element%n_dof_per_node = 4
    else if (Element%dim == 2) then
      Element%n_dof_per_node = 3
    end if

    Element%has_struct  = .true.
    Element%has_thermal = .true.
    Element%has_pore    = .false.

  end subroutine UF_Init_Continuum_Thermal

  subroutine UF_Init_Continuum_THM(Element, name)
    type(ElemType), intent(inout) :: Element
    character(len=*),     intent(in)    :: name

    character(len=len(name)) :: baseName
    integer(i4) :: L

    baseName = trim(name)
    L = len_trim(baseName)
    if (L >= 2 .and. baseName(L-1:L) == 'PT') then
      baseName = baseName(1:L-2)
    else if (L >= 1 .and. (baseName(L:L) == 'T' .or. baseName(L:L) == 'P')) then
      baseName = baseName(1:L-1)
    end if

    call UF_Init_Continuum(Element, baseName)
    Element%name = trim(name)
    Element%compute => Calc_Continuum_THM

    if (Element%dim == 3) then
      Element%n_dof_per_node = 5
    else if (Element%dim == 2) then
      Element%n_dof_per_node = 4
    end if

    Element%has_struct  = .true.
    Element%has_thermal = .true.
    Element%has_pore    = .true.

  end subroutine UF_Init_Continuum_THM

end module PH_ElemContm_Ops