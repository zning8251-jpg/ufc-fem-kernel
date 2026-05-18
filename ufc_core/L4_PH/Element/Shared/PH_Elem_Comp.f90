!===============================================================================
! MODULE: PH_Elem_Comp
! LAYER:  L4_PH
! DOMAIN: Element/Shared
! ROLE:   Proc
! BRIEF:  Composite beam/shell layer-wise integration (Element/Composite)
!===============================================================================
MODULE PH_Elem_Comp
!> Status: PROGRESSIVE (partial implementation, see Arg TYPE compliance mode)
! > Theory: Internal UFC architecture spec §1 (see UFC_ .md) | Last verified: 2026-02-14
  !! Runtime Composite Element Support Module
  !!   LAYER: L4 (Element Library)
  !!   DOMAIN: Element/Composite
  !!   KIND: Core (Composite element support & layer-wise integration)
  !! - Composite Beam Elements
  !! - Composite Shell Elements
  !! - Layer-wise Integration
  !! - Fiber-Matrix Behavior

  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Mem_Mgr, ONLY: UF_Mem_AllocReal1D, UF_Mem_FreeReal1D, MEM_DOMAIN_ELEM
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Base_ObjModel, ONLY: MatProperties
  USE MD_Elem_Mgr, ONLY: ElemType, ElemFormul, ElemCtx, &
                             ElemFlags, ElemState
  USE PH_ElemOrientRT_Brg, ONLY: RT_Orientation

  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  PUBLIC :: UF_BuildCompBeamStiff
  PUBLIC :: UF_BuildCompShellStiff
  PUBLIC :: UF_ComputeLayerStiffness
  PUBLIC :: UF_TransformLayerToGlobal
  PUBLIC :: CompLayerInfo
  PUBLIC :: CompMatInfo

  !=============================================================================
  ! INTF-001 3D Timoshenko
  ! Purpose: UF_Bu_3D 11
  ! Theory: Timoshenko : φ = 12EI/(GAκL²)
  ! 12×12 = (2) + (2) + y (4) + z (4)
  ! Status: Draft |
  !=============================================================================
  PUBLIC :: PH_Beam3DStiffArgs

  TYPE :: PH_Beam3DStiffArgs
    ! ---- ----
    REAL(wp) :: L       = 0.0_wp  !! (m)
    REAL(wp) :: A       = 0.0_wp  !! (m²)
    REAL(wp) :: Iy      = 0.0_wp  !! y (m�?
    REAL(wp) :: Iz      = 0.0_wp  !! z (m�?
    REAL(wp) :: J_tors  = 0.0_wp  !! (m�?

    ! ---- ----
    REAL(wp) :: E       = 0.0_wp  !! (Pa)
    REAL(wp) :: G       = 0.0_wp  !! (Pa)

    ! ---- ----
    REAL(wp) :: kappa_y = 5.0_wp/6.0_wp  !! y
    REAL(wp) :: kappa_z = 5.0_wp/6.0_wp  !! z

    ! ---- ----
    REAL(wp) :: Ke(12,12) = 0.0_wp  !! 12×12

    ! ---- ----
    TYPE(ErrorStatusType), POINTER :: status => NULL()  ! error status ptr (IF_Err)
  END TYPE PH_Beam3DStiffArgs



  !=============================================================================
  ! Composite Layer Information Type
  !=============================================================================
  TYPE, PUBLIC :: CompLayerInfo
    INTEGER(i4) :: layer_id = 0
    REAL(wp) :: thickness = 0.0_wp
    REAL(wp) :: fiber_angle = 0.0_wp  ! Fiber angle in degrees
    REAL(wp) :: z_bottom = 0.0_wp     ! Bottom z-coordinate in layer stack
    REAL(wp) :: z_top = 0.0_wp        ! Top z-coordinate in layer stack
    INTEGER(i4) :: material_id = 0    ! Mat ID for this layer
    REAL(wp), ALLOCATABLE :: material_props(:)  ! Mat properties
  END TYPE CompLayerInfo

  !=============================================================================
  ! Composite Mat Information Type
  !=============================================================================
  TYPE, PUBLIC :: CompMatInfo
    INTEGER(i4) :: n_layers = 0
    TYPE(CompLayerInfo), ALLOCATABLE :: layers(:)
    REAL(wp) :: total_thickness = 0.0_wp
    LOGICAL :: symmetric_layup = .false.  ! Whether layup is symmetric
    INTEGER(i4) :: integration_met = 1  ! 1=full, 2=reduced
    INTEGER(i4) :: n_integration_p = 5  ! Through-thickness integration points
  END TYPE CompMatInfo

CONTAINS

  SUBROUTINE UF_Bu_3D(L, E, A, Iy, Iz, G, J_torsion, kappa_y, kappa_z, Ke, status)
    !! Build 3D Timoshenko beam stiffness matrix (12x12)
    !!
    !! Parameters:
    !!   L: Beam length
    !!   E: Young's modulus
    !!   A: Cross-sectional area
    !!   Iy, Iz: Second moments of area about y and z axes
    !!   G: Shear modulus
    !!   J_torsion: Torsional constant
    !!   kappa_y, kappa_z: Shear correction factors
    !!   Ke: Output stiffness matrix (12x12)
    !!   status: Error status

    REAL(wp), INTENT(IN) :: L, E, A, Iy, Iz, G, J_torsion, kappa_y, kappa_z
    REAL(wp), INTENT(OUT) :: Ke(12, 12)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: EA, EIy, EIz, GJ
    REAL(wp) :: GA_shear_y, GA_shear_z
    REAL(wp) :: L2, L3
    REAL(wp) :: phi_y, phi_z
    REAL(wp) :: c2_y, c3_y, c4_y, c5_y, c6_y
    REAL(wp) :: c2_z, c3_z, c4_z, c5_z, c6_z

    CALL init_error_status(status)
    IF (L <= 0.0_wp .OR. E <= 0.0_wp .OR. A <= 0.0_wp) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid beam parameters"
      RETURN
    END IF

    EA = E * A
    EIy = E * Iy
    EIz = E * Iz
    GJ = G * J_torsion
    GA_shear_y = kappa_y * G * A
    GA_shear_z = kappa_z * G * A
    L2 = L * L
    L3 = L2 * L
    phi_y = 12.0_wp * EIy / (GA_shear_y * L2)
    phi_z = 12.0_wp * EIz / (GA_shear_z * L2)

    ! Coefficients for y-direction bending (around z-axis)
    c2_y = 12.0_wp * EIz / (L3 * (1.0_wp + phi_z))
    c3_y = 6.0_wp * EIz / (L2 * (1.0_wp + phi_z))
    c4_y = EIz * (4.0_wp + phi_z) / (L * (1.0_wp + phi_z))
    c5_y = EIz * (2.0_wp - phi_z) / (L * (1.0_wp + phi_z))
    c6_y = -12.0_wp * EIz / (L3 * (1.0_wp + phi_z))

    ! Coefficients for z-direction bending (around y-axis)
    c2_z = 12.0_wp * EIy / (L3 * (1.0_wp + phi_y))
    c3_z = 6.0_wp * EIy / (L2 * (1.0_wp + phi_y))
    c4_z = EIy * (4.0_wp + phi_y) / (L * (1.0_wp + phi_y))
    c5_z = EIy * (2.0_wp - phi_y) / (L * (1.0_wp + phi_y))
    c6_z = -12.0_wp * EIy / (L3 * (1.0_wp + phi_y))

    ! Initialize stiffness matrix
    Ke = 0.0_wp

    ! Axial stiffness
    Ke(1, 1) = EA / L
    Ke(1, 7) = -EA / L
    Ke(7, 1) = -EA / L
    Ke(7, 7) = EA / L

    ! Torsional stiffness
    Ke(4, 4) = GJ / L
    Ke(4, 10) = -GJ / L
    Ke(10, 4) = -GJ / L
    Ke(10, 10) = GJ / L

    ! Y-direction bending (around z-axis): DOFs 2, 6, 8, 12
    Ke(2, 2) = c2_y
    Ke(2, 6) = c3_y
    Ke(2, 8) = c6_y
    Ke(2, 12) = c3_y
    Ke(6, 2) = c3_y
    Ke(6, 6) = c4_y
    Ke(6, 8) = -c3_y
    Ke(6, 12) = c5_y
    Ke(8, 2) = c6_y
    Ke(8, 6) = -c3_y
    Ke(8, 8) = c2_y
    Ke(8, 12) = -c3_y
    Ke(12, 2) = c3_y
    Ke(12, 6) = c5_y
    Ke(12, 8) = -c3_y
    Ke(12, 12) = c4_y

    ! Z-direction bending (around y-axis): DOFs 3, 5, 9, 11
    Ke(3, 3) = c2_z
    Ke(3, 5) = -c3_z
    Ke(3, 9) = c6_z
    Ke(3, 11) = -c3_z
    Ke(5, 3) = -c3_z
    Ke(5, 5) = c4_z
    Ke(5, 9) = c3_z
    Ke(5, 11) = c5_z
    Ke(9, 3) = c6_z
    Ke(9, 5) = c3_z
    Ke(9, 9) = c2_z
    Ke(9, 11) = c3_z
    Ke(11, 3) = -c3_z
    Ke(11, 5) = c5_z
    Ke(11, 9) = c3_z
    Ke(11, 11) = c4_z

    status%status_code = IF_STATUS_OK

  END SUBROUTINE UF_BuildTimoshenkoBeamStiff_3D

  SUBROUTINE UF_BuildCompBeamStiff(L, composite_info, Ke, status)
    !! Build stiffness matrix for composite beam element
    !!
    !! Uses layer-wise integration through cross-section
    !! Each layer can have different Mat properties and fiber orientation

    REAL(wp), INTENT(IN) :: L
    TYPE(CompMatInfo), INTENT(IN) :: composite_info
    REAL(wp), INTENT(OUT) :: Ke(12, 12)  ! 12 DOFs for 2-node 3D beam
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: iLayer, ip, nIP_thickness
    INTEGER(i4) :: n_valid_layers
    REAL(wp) :: z, dz, weight, detJ
    REAL(wp) :: E_layer, nu_layer, G_layer
    REAL(wp) :: A_layer, Iy_layer, Iz_layer, J_torsion_layer
    REAL(wp) :: A_total, Iy_total, Iz_total, J_torsion_total
    REAL(wp) :: E_equiv, G_equiv
    REAL(wp), ALLOCATABLE :: z_coords(:), weights(:)
    REAL(wp) :: T_layer(3, 3)  ! Transformation matrix for layer
    REAL(wp) :: Ke_layer(12, 12)
    TYPE(RT_Orientation) :: orient_layer
    REAL(wp) :: theta_rad

    CALL init_error_status(status)

    IF (L <= 0.0_wp) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "UF_BuildCompBeamStiff: invalid beam length L"
      RETURN
    END IF

    IF (composite_info%n_layers <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "No layers defined for composite beam"
      RETURN
    END IF

    ! Init totals
    A_total = 0.0_wp
    Iy_total = 0.0_wp
    Iz_total = 0.0_wp
    J_torsion_total = 0.0_wp
    E_equiv = 0.0_wp
    G_equiv = 0.0_wp

    Ke = 0.0_wp
    n_valid_layers = 0

    ! Loop over layers
    DO iLayer = 1, composite_info%n_layers
      ! Get layer properties
      IF (.NOT. ALLOCATED(composite_info%layers(iLayer)%material_props)) THEN
        CYCLE
      END IF
      n_valid_layers = n_valid_layers + 1

      E_layer = composite_info%layers(iLayer)%material_props(1)
      nu_layer = composite_info%layers(iLayer)%material_props(2)
      G_layer = E_layer / (2.0_wp * (1.0_wp + nu_layer))

      ! Compute layer cross-section properties
      A_layer = composite_info%layers(iLayer)%thickness * 1.0_wp  ! Simplified: unit width
      Iy_layer = A_layer * composite_info%layers(iLayer)%thickness**2 / 12.0_wp
      Iz_layer = Iy_layer  ! Simplified: square cross-section
      J_torsion_layer = 2.0_wp * Iy_layer  ! Simplified

      ! INT-3:  ï¼? RT_Orientation
      theta_rad = composite_info%layers(iLayer)%fiber_angle * 3.141592653589793_wp / 180.0_wp
      CALL orient_layer%SetVectors( &
        axis_a=[COS(theta_rad), SIN(theta_rad), 0.0_wp], &
        axis_b=[-SIN(theta_rad), COS(theta_rad), 0.0_wp], &
        axis_c=[0.0_wp, 0.0_wp, 1.0_wp])
      CALL orient_layer%ComputeRotation()
      ! Transform layer properties based on fiber angle
      CALL UF_TransformLayerToGlobal(composite_info%layers(iLayer)%fiber_angle, &
                                     E_layer, nu_layer, G_layer, &
                                     T_layer, E_layer, nu_layer, G_layer)

      ! Accumulate equivalent properties
      A_total = A_total + A_layer
      Iy_total = Iy_total + Iy_layer
      Iz_total = Iz_total + Iz_layer
      J_torsion_total = J_torsion_total + J_torsion_layer
      E_equiv = E_equiv + E_layer * A_layer
      G_equiv = G_equiv + G_layer * A_layer
    END DO

    IF (n_valid_layers <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "UF_BuildCompBeamStiff: no layer with allocated material_props"
      RETURN
    END IF

    ! Compute equivalent properties
    IF (A_total > 0.0_wp) THEN
      E_equiv = E_equiv / A_total
      G_equiv = G_equiv / A_total
    ELSE
      E_equiv = 1.0e6_wp
      G_equiv = 1.0e6_wp / (2.0_wp * 1.3_wp)
    END IF

    ! Build beam stiffness using equivalent properties
    ! Use Timoshenko theory for composite beams (more accurate)
    CALL UF_BuildTimoshenkoBeamStiff_3D(L, E_equiv, A_total, Iy_total, &
                                            Iz_total, G_equiv, J_torsion_total, &
                                            5.0_wp/6.0_wp, 5.0_wp/6.0_wp, &
                                            Ke, status)

  END SUBROUTINE UF_BuildCompBeamStiff

  SUBROUTINE UF_BuildCompShellStiff(composite_info, Dm, Db, Ds, status)
    !! Build constitutive matrices for composite shell element
    !!
    !! Uses layer-wise integration through thickness
    !! Classical lamination theory (CLT)

    TYPE(CompMatInfo), INTENT(IN) :: composite_info
    REAL(wp), INTENT(OUT) :: Dm(3, 3), Db(3, 3), Ds(2, 2)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: iLayer, ip, nIP_thickness
    REAL(wp) :: z, dz, weight
    REAL(wp) :: E1, E2, nu12, G12, G13, G23
    REAL(wp) :: Q_layer(3, 3)  ! Reduced stiffness matrix for layer
    REAL(wp) :: Q_transformed(3, 3)  ! Transformed to global coordinates
    REAL(wp) :: z_bottom, z_top, z_mid
    REAL(wp), POINTER :: z_coords(:), weights(:)
    INTEGER(i4) :: z_coords_id, weights_id
    TYPE(ErrorStatusType) :: st
    REAL(wp) :: A_mat(3, 3), B_mat(3, 3), D_mat(3, 3)  ! ABD matrix components
    REAL(wp) :: As_mat(2, 2)  ! Shear stiffness matrix

    CALL init_error_status(status)
    z_coords => NULL()
    weights => NULL()
    z_coords_id = -1
    weights_id = -1

    IF (composite_info%n_layers <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "No layers defined for composite shell"
      RETURN
    END IF

    ! Init ABD matrices
    A_mat = 0.0_wp  ! Membrane stiffness
    B_mat = 0.0_wp  ! Coupling stiffness
    D_mat = 0.0_wp  ! Bending stiffness
    As_mat = 0.0_wp  ! Shear stiffness

    ! Get through-thickness integration points
    nIP_thickness = composite_info%n_integration_p
    CALL UF_Mem_AllocReal1D(MEM_DOMAIN_ELEM, 0_i4, nIP_thickness, 'Comp_z_coords', z_coords, z_coords_id, st)
    IF (st%status_code /= IF_STATUS_OK) THEN
      status = st
      GOTO 900
    END IF
    CALL UF_Mem_AllocReal1D(MEM_DOMAIN_ELEM, 0_i4, nIP_thickness, 'Comp_weights', weights, weights_id, st)
    IF (st%status_code /= IF_STATUS_OK) THEN
    status = st
    GOTO 900
    END IF

    ! Simplified: use Gauss points through thickness
    ! Full implementation would use proper integration scheme
    DO ip = 1, nIP_thickness
      z_coords(ip) = -0.5_wp + (ip - 0.5_wp) / REAL(nIP_thickness, wp)
      weights(ip) = 1.0_wp / REAL(nIP_thickness, wp)
    END DO

    ! Loop over layers
    DO iLayer = 1, composite_info%n_layers
      z_bottom = composite_info%layers(iLayer)%z_bottom
      z_top = composite_info%layers(iLayer)%z_top
      dz = z_top - z_bottom

      ! Get layer Mat properties
      IF (.NOT. ALLOCATED(composite_info%layers(iLayer)%material_props)) THEN
        CYCLE
      END IF

      ! Extract orthotropic properties (simplified)
      E1 = composite_info%layers(iLayer)%material_props(1)
      E2 = composite_info%layers(iLayer)%material_props(2)
      nu12 = composite_info%layers(iLayer)%material_props(3)
      G12 = composite_info%layers(iLayer)%material_props(4)
      G13 = G12  ! Simplified
      G23 = G12  ! Simplified

      ! Build reduced stiffness matrix Q for layer
      CALL UF_BuildOrthotropicQMatrix(E1, E2, nu12, G12, Q_layer)

      ! Transform Q to global coordinates based on fiber angle
      CALL UF_TransformQMatrixToGlobal(composite_info%layers(iLayer)%fiber_angle, &
                                      Q_layer, Q_transformed)

      ! Integrate through layer thickness
      DO ip = 1, nIP_thickness
        z = z_bottom + (z_coords(ip) + 1.0_wp) * 0.5_wp * dz
        weight = weights(ip) * dz

        ! Membrane stiffness: A = â«Q dz
        A_mat = A_mat + Q_transformed * weight

        ! Coupling stiffness: B = â«Q * z dz
        B_mat = B_mat + Q_transformed * z * weight

        ! Bending stiffness: D = â«Q * zÂ² dz
        D_mat = D_mat + Q_transformed * z * z * weight
      END DO

      ! Shear stiffness: As = â«G_shear dz
      As_mat(1, 1) = As_mat(1, 1) + G13 * dz
      As_mat(2, 2) = As_mat(2, 2) + G23 * dz
    END DO

    ! Extract constitutive matrices
    Dm = A_mat  ! Membrane stiffness
    Db = D_mat  ! Bending stiffness
    Ds = As_mat  ! Shear stiffness

    IF (MAXVAL(ABS(A_mat)) < 1.0e-30_wp .AND. &
        MAXVAL(ABS(D_mat)) < 1.0e-30_wp .AND. &
        MAXVAL(ABS(As_mat)) < 1.0e-30_wp) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "UF_BuildCompShellStiff: zero ABD (no valid layer material_props integrated)"
      GOTO 900
    END IF

    CALL init_error_status(status, IF_STATUS_OK)

    ! Note: B_mat (coupling) is typically zero for symmetric layups
    ! For unsymmetric layups, would need to handle coupling

900 CONTINUE
    IF (weights_id >= 0) CALL UF_Mem_FreeReal1D(weights_id, st)
    IF (z_coords_id >= 0) CALL UF_Mem_FreeReal1D(z_coords_id, st)

  END SUBROUTINE UF_BuildCompShellStiff

  SUBROUTINE UF_BuildOrthotropicQMatrix(E1, E2, nu12, G12, Q)
    !! Build reduced stiffness matrix Q for orthotropic Mat (plane sigma)

    REAL(wp), INTENT(IN) :: E1, E2, nu12, G12
    REAL(wp), INTENT(OUT) :: Q(3, 3)

    REAL(wp) :: nu21, denom

    nu21 = nu12 * E2 / E1
    denom = 1.0_wp - nu12 * nu21

    Q = 0.0_wp
    Q(1, 1) = E1 / denom
    Q(1, 2) = nu12 * E2 / denom
    Q(2, 1) = Q(1, 2)
    Q(2, 2) = E2 / denom
    Q(3, 3) = G12

  END SUBROUTINE UF_BuildOrthotropicQMatrix

  SUBROUTINE UF_ComputeLayerStiffness(layer_info, Q_matrix, status)
    !! Compute reduced stiffness matrix Q for a composite layer

    TYPE(CompLayerInfo), INTENT(IN) :: layer_info
    REAL(wp), INTENT(OUT) :: Q_matrix(3, 3)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: E1, E2, nu12, G12, nu21
    REAL(wp) :: denom

    CALL init_error_status(status)

    IF (.NOT. ALLOCATED(layer_info%material_props)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Layer Mat properties not allocated"
      RETURN
    END IF

    ! Extract orthotropic properties
    E1 = layer_info%material_props(1)
    E2 = layer_info%material_props(2)
    nu12 = layer_info%material_props(3)
    G12 = layer_info%material_props(4)

    ! Compute nu21 from symmetry
    nu21 = nu12 * E2 / E1
    denom = 1.0_wp - nu12 * nu21

    ! Build reduced stiffness matrix Q (plane sigma)
    Q_matrix = 0.0_wp
    Q_matrix(1, 1) = E1 / denom
    Q_matrix(1, 2) = nu12 * E2 / denom
    Q_matrix(2, 1) = Q_matrix(1, 2)
    Q_matrix(2, 2) = E2 / denom
    Q_matrix(3, 3) = G12

    status%status_code = IF_STATUS_OK

  END SUBROUTINE UF_ComputeLayerStiffness

  SUBROUTINE UF_TransformLayerToGlobal(fiber_angle, E_local, nu_local, G_local, &
                                        T_matrix, E_global, nu_global, G_global)
    !! Transform layer properties from local (fiber) to global coordinates

    REAL(wp), INTENT(IN) :: fiber_angle  ! In degrees
    REAL(wp), INTENT(IN) :: E_local, nu_local, G_local
    REAL(wp), INTENT(OUT) :: T_matrix(3, 3)
    REAL(wp), INTENT(OUT) :: E_global, nu_global, G_global

    REAL(wp) :: theta, c, s, c2, s2, cs
    REAL(wp) :: Q_local(3, 3), Q_global(3, 3)

    ! Convert angle to radians
    theta = fiber_angle * 3.141592653589793_wp / 180.0_wp
    c = COS(theta)
    s = SIN(theta)
    c2 = c * c
    s2 = s * s
    cs = c * s

    ! Build transformation matrix
    T_matrix(1, 1) = c2
    T_matrix(1, 2) = s2
    T_matrix(1, 3) = 2.0_wp * cs
    T_matrix(2, 1) = s2
    T_matrix(2, 2) = c2
    T_matrix(2, 3) = -2.0_wp * cs
    T_matrix(3, 1) = -cs
    T_matrix(3, 2) = cs
    T_matrix(3, 3) = c2 - s2

    ! For simplified output, use transformed values
    ! Full implementation would transform Q matrix
    E_global = E_local  ! Simplified
    nu_global = nu_local
    G_global = G_local

  END SUBROUTINE UF_TransformLayerToGlobal

  SUBROUTINE UF_TransformQMatrixToGlobal(fiber_angle, Q_local, Q_global)
    !! Transform Q matrix from local (fiber) to global coordinates

    REAL(wp), INTENT(IN) :: fiber_angle  ! In degrees
    REAL(wp), INTENT(IN) :: Q_local(3, 3)
    REAL(wp), INTENT(OUT) :: Q_global(3, 3)

    REAL(wp) :: theta, c, s, c2, s2, cs
    REAL(wp) :: T(3, 3), T_inv(3, 3)

    ! Convert angle to radians
    theta = fiber_angle * 3.141592653589793_wp / 180.0_wp
    c = COS(theta)
    s = SIN(theta)
    c2 = c * c
    s2 = s * s
    cs = c * s

    ! Build transformation matrix T
    T(1, 1) = c2
    T(1, 2) = s2
    T(1, 3) = 2.0_wp * cs
    T(2, 1) = s2
    T(2, 2) = c2
    T(2, 3) = -2.0_wp * cs
    T(3, 1) = -cs
    T(3, 2) = cs
    T(3, 3) = c2 - s2

    ! Build inverse transformation matrix
    T_inv(1, 1) = c2
    T_inv(1, 2) = s2
    T_inv(1, 3) = -2.0_wp * cs
    T_inv(2, 1) = s2
    T_inv(2, 2) = c2
    T_inv(2, 3) = 2.0_wp * cs
    T_inv(3, 1) = cs
    T_inv(3, 2) = -cs
    T_inv(3, 3) = c2 - s2

    ! Transform: Q_global = T^T * Q_local * T
    Q_global = MATMUL(MATMUL(TRANSPOSE(T), Q_local), T)

  END SUBROUTINE UF_TransformQMatrixToGlobal
END MODULE PH_Elem_Comp