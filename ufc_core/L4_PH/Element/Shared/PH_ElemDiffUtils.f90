!===============================================================================
! MODULE: PH_ElemDiffUtils
! LAYER:  L4_PH
! DOMAIN: Element/Shared
! ROLE:   Proc
! BRIEF:  Elem Diff Utils module (auto-filled)
!===============================================================================
MODULE PH_ElemDiffUtils
!> Status: PROGRESSIVE (partial implementation, see Arg TYPE compliance mode)
! > Theory: Internal UFC architecture spec §1 (see UFC_ .md) | Last verified: 2026-02-14
  USE IF_Prec_Core, only: wp, i4
  use MD_Base_ElemLib, only: UF_GetGaussPoints, UF_GetShapeFunctions, UF_ComputeJacobian
  USE MD_Base_Enums, only: UF_TOPO_Hex, UF_TOPO_Quad, UF_TOPO_Wedge
  USE MD_Elem_Mgr, only: ElemType, ElemFormul, ElemCtx, ShapeFuncResult
  use MD_Out_UniFld, only: DiffIpKernel_Proc
  implicit none
  private

  public :: DiffGauss

  !=============================================================================
  ! INTF-001 Arg TYPE
  !=============================================================================
  PUBLIC :: PH_Elem_Shared_Args
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


contains

  integer(i4) function GetEffOrder_Diff(ElemType, Formul) result(order)
    type(ElemType), intent(in) :: ElemType
    type(ElemFormul), intent(in) :: Formul
    integer(i4) :: nNode

    nNode = ElemType%pop%n_nodes

    if (index(ElemType%name, 'R') > 0) then
       order = 1
       if (nNode > 8 .and. ElemType%topo == UF_TOPO_Hex) order = 2
       if (ElemType%topo == UF_TOPO_Quad .and. nNode > 4) order = 2
    else
       order = 2
       if (ElemType%topo == UF_TOPO_Hex .and. nNode > 8) order = 3
       if (ElemType%topo == UF_TOPO_Quad .and. nNode > 4) order = 3
       if (ElemType%topo == UF_TOPO_Wedge) order = 2
    end if

    if (Formul%reducedintegrat) then
       select case (ElemType%topo)
       case (UF_TOPO_Hex)
          if (nNode == 8) order = 1
          if (nNode > 8) order = 2
       case (UF_TOPO_Quad)
          if (nNode == 4) order = 1
          if (nNode > 4) order = 2
       case default
       end select
    end if
  end function GetEffOrder_Diff

  subroutine DiffGauss(ElemType, Formul, Ctx, &
                       field, field_incr, hasTransient, &
                       ipCoeffProc, Ke, C)
    type(ElemType),        intent(in)    :: ElemType
    type(ElemFormul),   intent(in)    :: Formul
    type(ElemCtx),    intent(in)    :: Ctx
    real(wp), allocatable,   intent(in), optional :: field(:)
    real(wp), allocatable,   intent(in), optional :: field_incr(:)
    logical,                 intent(in)    :: hasTransient
    procedure(DiffIpKernel_Proc)           :: ipCoeffProc

    real(wp),                intent(inout) :: Ke(:,:)
    real(wp),                intent(inout) :: C(:,:)

    integer(i4) :: nNode, nDim, ip, nInt
    integer(i4) :: iNode, jNode, aDim
    integer(i4) :: integrationorde
    logical     :: isAxisym
    real(wp), allocatable :: gaussCoords(:,:), weights(:)
    type(ShapeFuncResult) :: sf
    real(wp), allocatable :: dN_dx(:,:)
    real(wp) :: detJ, dVol, radius, r_coord
    real(wp) :: field_ip, field_old_ip
    real(wp) :: gradni_dot_grad, Nij
    real(wp) :: k_eff_ip, C_eff_ip

    nNode = ElemType%pop%n_nodes
    nDim  = ElemType%dim
    isAxisym = (index(ElemType%name, 'CAX') > 0)

    integrationorde = GetEffOrder_Diff(ElemType, Formul)
    call UF_GetGaussPoints(ElemType%topo, integrationorde, nDim, gaussCoords, weights)
    nInt = size(weights)

    do ip = 1, nInt
      call UF_GetShapeFunctions(ElemType%name, gaussCoords(:,ip), sf)

      call UF_ComputeJacobian(Ctx%coords_ref(1:nDim, :), sf%dN_dxi, detJ, dN_dx)

      dVol = detJ * weights(ip)

      radius = 0.0_wp
      if (isAxisym) then
        do iNode = 1, nNode
          r_coord = Ctx%coords_ref(1, iNode)
          radius  = radius + sf%N(iNode) * r_coord
        end do
        if (radius < 1.0e-10_wp) radius = 1.0e-10_wp
        dVol = dVol * 6.283185307179586_wp * radius
      else if (nDim == 2) then
        dVol = dVol * 1.0_wp
      end if

      field_ip     = 0.0_wp
      field_old_ip = 0.0_wp
      if (present(field)) then
        if (allocated(field)) then
          do jNode = 1, min(nNode, size(field))
            field_ip = field_ip + sf%N(jNode) * field(jNode)
          end do
        end if
      end if
      if (present(field_incr)) then
        if (allocated(field_incr)) then
          do jNode = 1, min(nNode, size(field_incr))
            field_old_ip = field_old_ip + sf%N(jNode) * field_incr(jNode)
          end do
        end if
      end if
      field_old_ip = field_ip - field_old_ip

      call ipCoeffProc(ip, sf, field_ip, field_old_ip, k_eff_ip, C_eff_ip)

      if (k_eff_ip > 0.0_wp) then
        do iNode = 1, nNode
          do jNode = 1, nNode
            gradni_dot_grad = 0.0_wp
            do aDim = 1, nDim
              gradni_dot_grad = gradni_dot_grad + dN_dx(iNode, aDim) * dN_dx(jNode, aDim)
            end do
            Ke(iNode, jNode) = Ke(iNode, jNode) + k_eff_ip * gradni_dot_grad * dVol
          end do
        end do
      end if

      if (hasTransient .and. C_eff_ip /= 0.0_wp) then
        do iNode = 1, nNode
          do jNode = 1, nNode
            Nij = sf%N(iNode) * sf%N(jNode)
            C(iNode, jNode) = C(iNode, jNode) + C_eff_ip * Nij * dVol
          end do
        end do
      end if

    end do

    if (allocated(dN_dx))       deallocate(dN_dx)
    if (allocated(gaussCoords)) deallocate(gaussCoords)
    if (allocated(weights))     deallocate(weights)
  end subroutine DiffGauss

end module PH_ElemDiffUtils
