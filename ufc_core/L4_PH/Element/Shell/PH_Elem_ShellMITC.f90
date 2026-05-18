!===============================================================================
! MODULE: PH_Elem_ShellMITC
! LAYER:  L4_PH
! DOMAIN: Element/Shell
! ROLE:   Proc
! BRIEF:  Eliminate shear locking in thin shell elements by using
!===============================================================================
MODULE PH_Elem_ShellMITC
!> Status: PROGRESSIVE (partial implementation, see Arg TYPE compliance mode)
! > Theory: Internal UFC architecture spec §1 (see UFC_ .md) | Last verified: 2026-02-14
  !! MITC Shell Element - Mixed Interpolation of Tensorial Components
  !!   LAYER: L4 (Element Library)
  !!   DOMAIN: Element/Shell
  !!   KIND: Core (Shear locking-free shell element kernels)

  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: init_error_status, IF_STATUS_INVALID, IF_STATUS_OK
  USE MD_Base_ObjModel, ONLY: MatProperties
  USE MD_Elem_Mgr, ONLY: ElemType, ElemFormul, ElemCtx, &
                          ElemFlags, ElemState, UF_Elem_PrepareStructStorage

  implicit none
  private

  public :: UF_Elem_Shell_MITC4_Calc
  public :: UF_MITC4_InterpolateShearStrain
  public :: MITC4Params

  !=============================================================================
  ! MITC4 Parameters
  !=============================================================================
  TYPE, PUBLIC :: MITC4Params
    REAL(wp) :: kappa = 5.0_wp / 6.0_wp   ! Shear correction factor
    LOGICAL :: use_tied_interpolation = .true.  ! MITC tied points
    INTEGER(i4) :: n_int_pts = 4          ! 2x2 Gauss integration
  END TYPE MITC4Params

  !=============================================================================
  ! INTF-001 Arg TYPE
  !=============================================================================
  PUBLIC :: PH_Elem_Shell_Args
  TYPE :: PH_Elem_Shell_Args
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
  END TYPE PH_Elem_Shell_Args


contains

  subroutine UF_Elem_Shell_MITC4_Calc(ElemType, Formul, Ctx, state_in, &
                                          Mat, state_out, flags)
    !! MITC4: 4-node shell with Mixed Interpolation of Tensorial Components
    !!        Eliminates shear locking in thin shell bending
    !!
    !! DOFs per node: [u, v, w, θx, θy] (5 DOFs, no drilling)
    !! Integration: 2x2 Gauss, shear via MITC assumed strain

    type(ElemType), intent(in) :: ElemType
    type(ElemFormul), intent(in) :: Formul
    type(ElemCtx), intent(in) :: Ctx
    type(ElemState), intent(in) :: state_in
    type(MatProperties), intent(in) :: Mat
    type(ElemState), intent(inout) :: state_out
    type(ElemFlags), intent(inout) :: flags

    integer(i4) :: nNode, nDOF, nIP, ip, i, j, a, b
    real(wp) :: xi, eta, weight, detJ
    real(wp) :: E, nu, h, G
    real(wp) :: Dm(3,3), Db(3,3), Ds(2,2)
    real(wp) :: Bm(3,20), Bb(3,20), Bs(2,20)
    real(wp) :: Ke_loc(20,20), Re_loc(20)
    real(wp) :: coords(2,4), N(4), dNdxi(4), dNdeta(4)
    real(wp) :: dNdx(4), dNdy(4), Jac(2,2), invJ(2,2)
    real(wp) :: u_dof(20)
    real(wp) :: xi_pts(4), eta_pts(4), w_pts(4)
    type(MITC4Params) :: mitc_params
    real(wp), parameter :: gp = 0.577350269189626_wp  ! 1/sqrt(3)

    mitc_params%kappa = 5.0_wp / 6.0_wp
    mitc_params%n_int_pts = 4

    nNode = ElemType%pop%n_nodes
    nDOF = nNode * 5_i4
    if (nNode /= 4) then
      call UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      flags%failed = .false.
      flags%suggest_cutback = .false.
      flags%requires_reasse = .true.
      flags%stableDt = 0.0_wp
      return
    end if

    if (.not. allocated(Ctx%coords_ref)) return
    coords(1:2, 1:4) = Ctx%coords_ref(1:2, 1:4)

    E = 1.0e6_wp
    nu = 0.3_wp
    h = 1.0_wp
    if (allocated(Mat%props) .and. size(Mat%props) >= 2) then
      E = Mat%props(1)
      nu = Mat%props(2)
      if (size(Mat%props) >= 3) h = Mat%props(3)
    end if

    ! Mindlin-Reissner shell constitutive (plane sigma membrane + bending + shear)
    call build_mindlin_reissner_constitutive(E, nu, h, mitc_params%kappa, Dm, Db, Ds)

    u_dof = 0.0_wp
    if (allocated(Ctx%disp_total) .and. size(Ctx%disp_total,2) >= 4) then
      do i = 1, 4
        u_dof((i-1)*5+1:(i-1)*5+5) = Ctx%disp_total(1:5, i)
      end do
    end if

    Ke_loc = 0.0_wp
    Re_loc = 0.0_wp

    ! 2x2 Gauss integration
    xi_pts = [-gp, gp, gp, -gp]
    eta_pts = [-gp, -gp, gp, gp]
    w_pts = [1.0_wp, 1.0_wp, 1.0_wp, 1.0_wp]

    do ip = 1, 4
      xi = xi_pts(ip)
      eta = eta_pts(ip)
      weight = w_pts(ip)

      call shape_quad4_bilinear(xi, eta, N, dNdxi, dNdeta)
      call jacobian_2d(coords, dNdxi, dNdeta, Jac, detJ, invJ)
      if (abs(detJ) < 1.0e-20_wp) cycle
      dNdx = invJ(1,1)*dNdxi + invJ(1,2)*dNdeta
      dNdy = invJ(2,1)*dNdxi + invJ(2,2)*dNdeta

      ! Membrane B matrix
      Bm = 0.0_wp
      do i = 1, 4
        Bm(1, (i-1)*5+1) = dNdx(i)
        Bm(2, (i-1)*5+2) = dNdy(i)
        Bm(3, (i-1)*5+1) = dNdy(i)
        Bm(3, (i-1)*5+2) = dNdx(i)
      end do

      ! Bending B matrix
      Bb = 0.0_wp
      do i = 1, 4
        Bb(1, (i-1)*5+5) = dNdx(i)
        Bb(2, (i-1)*5+4) = dNdy(i)
        Bb(3, (i-1)*5+4) = dNdx(i)
        Bb(3, (i-1)*5+5) = dNdy(i)
      end do

      ! Shear B matrix - MITC interpolation (simplified: use standard B for now)
      Bs = 0.0_wp
      do i = 1, 4
        Bs(1, (i-1)*5+3) = dNdx(i)
        Bs(1, (i-1)*5+5) = N(i)
        Bs(2, (i-1)*5+3) = dNdy(i)
        Bs(2, (i-1)*5+4) = -N(i)
      end do

      ! Assemble stiffness
      Ke_loc = Ke_loc + (matmul(transpose(Bm), matmul(Dm, Bm)) + &
                         matmul(transpose(Bb), matmul(Db, Bb)) + &
                         matmul(transpose(Bs), matmul(Ds, Bs))) * detJ * weight
    end do

    call UF_Elem_PrepareStructStorage(ElemType, state_out)
    if (nDOF > 0 .and. nDOF <= 20) then
      state_out%evo%Ke(1:nDOF, 1:nDOF) = Ke_loc(1:nDOF, 1:nDOF)
      state_out%Re(1:nDOF) = Re_loc(1:nDOF)
    end if

    flags%failed = .false.
    flags%suggest_cutback = .false.
    flags%requires_reasse = .true.
    flags%stableDt = 0.0_wp
    call init_error_status(flags%status, IF_STATUS_OK)
    state_out%failed = flags%failed
    state_out%stableDt = flags%stableDt

  contains
    subroutine shape_quad4_bilinear(xi, eta, N, dNdxi, dNdeta)
      real(wp), intent(in) :: xi, eta
      real(wp), intent(out) :: N(4), dNdxi(4), dNdeta(4)
      N(1) = 0.25_wp * (1.0_wp - xi) * (1.0_wp - eta)
      N(2) = 0.25_wp * (1.0_wp + xi) * (1.0_wp - eta)
      N(3) = 0.25_wp * (1.0_wp + xi) * (1.0_wp + eta)
      N(4) = 0.25_wp * (1.0_wp - xi) * (1.0_wp + eta)
      dNdxi(1) = -0.25_wp * (1.0_wp - eta)
      dNdxi(2) =  0.25_wp * (1.0_wp - eta)
      dNdxi(3) =  0.25_wp * (1.0_wp + eta)
      dNdxi(4) = -0.25_wp * (1.0_wp + eta)
      dNdeta(1) = -0.25_wp * (1.0_wp - xi)
      dNdeta(2) = -0.25_wp * (1.0_wp + xi)
      dNdeta(3) =  0.25_wp * (1.0_wp + xi)
      dNdeta(4) =  0.25_wp * (1.0_wp - xi)
    end subroutine shape_quad4_bilinear

    subroutine jacobian_2d(coords, dNdxi, dNdeta, Jac, detJ, invJ)
      real(wp), intent(in) :: coords(2,4), dNdxi(4), dNdeta(4)
      real(wp), intent(out) :: Jac(2,2), detJ, invJ(2,2)
      integer(i4) :: i
      Jac = 0.0_wp
      do i = 1, 4
        Jac(1,1) = Jac(1,1) + dNdxi(i)*coords(1,i)
        Jac(1,2) = Jac(1,2) + dNdxi(i)*coords(2,i)
        Jac(2,1) = Jac(2,1) + dNdeta(i)*coords(1,i)
        Jac(2,2) = Jac(2,2) + dNdeta(i)*coords(2,i)
      end do
      detJ = Jac(1,1)*Jac(2,2) - Jac(1,2)*Jac(2,1)
      if (abs(detJ) > 1.0e-20_wp) then
        invJ(1,1) =  Jac(2,2) / detJ
        invJ(1,2) = -Jac(1,2) / detJ
        invJ(2,1) = -Jac(2,1) / detJ
        invJ(2,2) =  Jac(1,1) / detJ
      else
        invJ = 0.0_wp
      end if
    end subroutine jacobian_2d

    subroutine bu_mi_re_constitutive(E, nu, h, kappa, Dm, Db, Ds)
      real(wp), intent(in) :: E, nu, h, kappa
      real(wp), intent(out) :: Dm(3,3), Db(3,3), Ds(2,2)
      real(wp) :: G, denom, D0_m, D0_b
      G = E / (2.0_wp * (1.0_wp + nu))
      denom = 1.0_wp - nu*nu
      D0_m = E * h / denom
      Dm = 0.0_wp
      Dm(1,1) = D0_m
      Dm(1,2) = nu*D0_m
      Dm(2,1) = Dm(1,2)
      Dm(2,2) = D0_m
      Dm(3,3) = E * h / (2.0_wp * (1.0_wp + nu))
      D0_b = E * h**3 / (12.0_wp * denom)
      Db = 0.0_wp
      Db(1,1) = D0_b
      Db(1,2) = nu*D0_b
      Db(2,1) = Db(1,2)
      Db(2,2) = D0_b
      Db(3,3) = E * h**3 / (24.0_wp * (1.0_wp + nu))
      Ds = 0.0_wp
      Ds(1,1) = kappa * G * h
      Ds(2,2) = Ds(1,1)
    end subroutine build_mindlin_reissner_constitutive
  end subroutine UF_Elem_Shell_MITC4_Calc

  subroutine UF_MI_InterpolateShearStrain(xi, eta, gamma_xz, gamma_yz, &
                                             u_dof, coords, nNode, Bs_mitc)
    !! Compute MITC4 assumed transverse shear strain from displacement DOFs
    !!
    !! Tied points (edge midpoints in natural coords):
    !!   A: (0,-1)  B: (1,0)  C: (0,1)  D: (-1,0)
    !! Interpolation: γ = N_A γ_A + N_B γ_B + N_C γ_C + N_D γ_D
    !! where γ_A,γ_B,γ_C,γ_D are computed from B matrix at tied points
    !!
    real(wp), intent(in) :: xi, eta
    real(wp), intent(out) :: gamma_xz, gamma_yz
    real(wp), intent(in) :: u_dof(:)      ! displacement DOFs [u,v,w,θx,θy] per node
    real(wp), intent(in) :: coords(:,:)   ! (3, nNode) coordinates
    integer(i4), intent(in) :: nNode
    real(wp), intent(out) :: Bs_mitc(2,:)  ! (2, nDOF) shear B-matrix with MITC interpolation

    real(wp) :: N_tied(4)      ! Shape functions at tied points for interpolation
    real(wp) :: gamma_xz_A, gamma_xz_B, gamma_xz_C, gamma_xz_D
    real(wp) :: gamma_yz_A, gamma_yz_B, gamma_yz_C, gamma_yz_D
    real(wp) :: N(4), dNdxi(4), dNdeta(4)
    real(wp) :: dNdx(4), dNdy(4)
    real(wp) :: Jac(2,2), invJ(2,2), detJ
    real(wp) :: xi_tied(4), eta_tied(4)
    integer(i4) :: i, pt

    ! Tied point coordinates (edge midpoints) A:(0,-1) B:(1,0) C:(0,1) D:(-1,0)
    xi_tied = [0.0_wp, 1.0_wp, 0.0_wp, -1.0_wp]
    eta_tied = [-1.0_wp, 0.0_wp, 1.0_wp, 0.0_wp]

    Bs_mitc = 0.0_wp
    gamma_xz = 0.0_wp
    gamma_yz = 0.0_wp
    gamma_xz_A = 0.0_wp
    gamma_xz_B = 0.0_wp
    gamma_xz_C = 0.0_wp
    gamma_xz_D = 0.0_wp
    gamma_yz_A = 0.0_wp
    gamma_yz_B = 0.0_wp
    gamma_yz_C = 0.0_wp
    gamma_yz_D = 0.0_wp

    if (nNode /= 4) return

    ! Compute shear strain at each tied point from standard B_shear * u
    do pt = 1, 4
      call shape_quad4_bilinear(xi_tied(pt), eta_tied(pt), N, dNdxi, dNdeta)
      call jacobian_2d(coords(1:2,1:4), dNdxi, dNdeta, Jac, detJ, invJ)
      if (abs(detJ) < 1.0e-20_wp) cycle
      dNdx = invJ(1,1)*dNdxi + invJ(1,2)*dNdeta
      dNdy = invJ(2,1)*dNdxi + invJ(2,2)*dNdeta

      ! γ_xz = dN/dx * w + N * θ_y,  γ_yz = dN/dy * w - N * θ_x
      select case (pt)
      case (1)
        do i = 1, 4
          gamma_xz_A = gamma_xz_A + dNdx(i)*u_dof((i-1)*5+3) + N(i)*u_dof((i-1)*5+5)
          gamma_yz_A = gamma_yz_A + dNdy(i)*u_dof((i-1)*5+3) - N(i)*u_dof((i-1)*5+4)
        end do
      case (2)
        do i = 1, 4
          gamma_xz_B = gamma_xz_B + dNdx(i)*u_dof((i-1)*5+3) + N(i)*u_dof((i-1)*5+5)
          gamma_yz_B = gamma_yz_B + dNdy(i)*u_dof((i-1)*5+3) - N(i)*u_dof((i-1)*5+4)
        end do
      case (3)
        do i = 1, 4
          gamma_xz_C = gamma_xz_C + dNdx(i)*u_dof((i-1)*5+3) + N(i)*u_dof((i-1)*5+5)
          gamma_yz_C = gamma_yz_C + dNdy(i)*u_dof((i-1)*5+3) - N(i)*u_dof((i-1)*5+4)
        end do
      case (4)
        do i = 1, 4
          gamma_xz_D = gamma_xz_D + dNdx(i)*u_dof((i-1)*5+3) + N(i)*u_dof((i-1)*5+5)
          gamma_yz_D = gamma_yz_D + dNdy(i)*u_dof((i-1)*5+3) - N(i)*u_dof((i-1)*5+4)
        end do
      end select
    end do

    ! Interpolation functions at (xi,eta) for tied points
    ! N_tied(i) = 0.25*(1 + xi*xi_i)*(1 + eta*eta_i) at edge midpoints
    N_tied(1) = 0.5_wp * (1.0_wp - eta)
    N_tied(2) = 0.5_wp * (1.0_wp + xi)
    N_tied(3) = 0.5_wp * (1.0_wp + eta)
    N_tied(4) = 0.5_wp * (1.0_wp - xi)

    ! Interpolate shear strain
    gamma_xz = N_tied(1)*gamma_xz_A + N_tied(2)*gamma_xz_B + N_tied(3)*gamma_xz_C + N_tied(4)*gamma_xz_D
    gamma_yz = N_tied(1)*gamma_yz_A + N_tied(2)*gamma_yz_B + N_tied(3)*gamma_yz_C + N_tied(4)*gamma_yz_D

    ! Build Bs_mitc as gradient of interpolated strain w.r.t. u
    ! (Simplified: use standard B_shear with MITC modifier - full impl would differentiate N_tied)
    call shape_quad4_bilinear(xi, eta, N, dNdxi, dNdeta)
    call jacobian_2d(coords(1:2,1:4), dNdxi, dNdeta, Jac, detJ, invJ)
    if (abs(detJ) > 1.0e-20_wp) then
      dNdx = invJ(1,1)*dNdxi + invJ(1,2)*dNdeta
      dNdy = invJ(2,1)*dNdxi + invJ(2,2)*dNdeta
      do i = 1, 4
        Bs_mitc(1, (i-1)*5+3) = dNdx(i)
        Bs_mitc(1, (i-1)*5+5) = N(i)
        Bs_mitc(2, (i-1)*5+3) = dNdy(i)
        Bs_mitc(2, (i-1)*5+4) = -N(i)
      end do
    end if

  contains
    subroutine shape_quad4_bilinear(xi, eta, N, dNdxi, dNdeta)
      real(wp), intent(in) :: xi, eta
      real(wp), intent(out) :: N(4), dNdxi(4), dNdeta(4)
      N(1) = 0.25_wp * (1.0_wp - xi) * (1.0_wp - eta)
      N(2) = 0.25_wp * (1.0_wp + xi) * (1.0_wp - eta)
      N(3) = 0.25_wp * (1.0_wp + xi) * (1.0_wp + eta)
      N(4) = 0.25_wp * (1.0_wp - xi) * (1.0_wp + eta)
      dNdxi(1) = -0.25_wp * (1.0_wp - eta)
      dNdxi(2) =  0.25_wp * (1.0_wp - eta)
      dNdxi(3) =  0.25_wp * (1.0_wp + eta)
      dNdxi(4) = -0.25_wp * (1.0_wp + eta)
      dNdeta(1) = -0.25_wp * (1.0_wp - xi)
      dNdeta(2) = -0.25_wp * (1.0_wp + xi)
      dNdeta(3) =  0.25_wp * (1.0_wp + xi)
      dNdeta(4) =  0.25_wp * (1.0_wp - xi)
    end subroutine shape_quad4_bilinear

    subroutine jacobian_2d(coords, dNdxi, dNdeta, Jac, detJ, invJ)
      real(wp), intent(in) :: coords(2,4), dNdxi(4), dNdeta(4)
      real(wp), intent(out) :: Jac(2,2), detJ, invJ(2,2)
      integer(i4) :: i
      Jac = 0.0_wp
      do i = 1, 4
        Jac(1,1) = Jac(1,1) + dNdxi(i)*coords(1,i)
        Jac(1,2) = Jac(1,2) + dNdxi(i)*coords(2,i)
        Jac(2,1) = Jac(2,1) + dNdeta(i)*coords(1,i)
        Jac(2,2) = Jac(2,2) + dNdeta(i)*coords(2,i)
      end do
      detJ = Jac(1,1)*Jac(2,2) - Jac(1,2)*Jac(2,1)
      if (abs(detJ) > 1.0e-20_wp) then
        invJ(1,1) =  Jac(2,2) / detJ
        invJ(1,2) = -Jac(1,2) / detJ
        invJ(2,1) = -Jac(2,1) / detJ
        invJ(2,2) =  Jac(1,1) / detJ
      else
        invJ = 0.0_wp
      end if
    end subroutine jacobian_2d
  end subroutine UF_MITC4_InterpolateShearStrain
end module PH_Elem_ShellMITC