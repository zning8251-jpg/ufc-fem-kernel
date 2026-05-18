!===============================================================================
! Module: HARNESS_Elem_Mass_Lumped
! Layer:  L4_PH - Physics Layer (Harness)
! Domain: Element
! Purpose: Harness acceptance test — lumped mass matrix for C3D8 element.
!          Verifies total mass = rho * V and diagonal sum = total mass.
!
! Theory:
!   Consistent mass: Me = INT rho * N^T * N dV
!   Lumped mass (row-sum): M_L(i,i) = SUM_j Me(i,j)
!   Total mass: sum(M_L) = rho * V  (mass conservation)
!   For C3D8 unit cube with rho=7800:
!     V = 1 m^3,  total mass = 7800 kg
!     Each node: m_node = 7800/8 = 975 kg
!     Each DOF diagonal: 975 kg (3 DOFs per node, each gets m_node)
!
! Parameters: rho = 7800 kg/m^3, unit cube
!
! Status: Harness | Created: 2026-04-28
!===============================================================================
MODULE HARNESS_Elem_Mass_Lumped
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: Run_Harness_Elem_Mass_Lumped

  REAL(wp), PARAMETER :: TOL = 1.0e-10_wp

CONTAINS

  SUBROUTINE Run_Harness_Elem_Mass_Lumped()
    REAL(wp) :: rho, volume
    REAL(wp) :: total_mass_expected, node_mass
    REAL(wp) :: M_consistent(24,24)
    REAL(wp) :: M_lumped(24)
    REAL(wp) :: total_mass_lumped, total_mass_consistent
    REAL(wp) :: err
    INTEGER(i4) :: i, j, n_pass, n_fail
    REAL(wp) :: N(8)   ! shape functions at a Gauss point
    REAL(wp) :: xi(8,3), w(8)  ! 2x2x2 Gauss points
    REAL(wp) :: detJ, wdetJ
    INTEGER(i4) :: igp, inode, jnode, idof, jdof

    n_pass = 0
    n_fail = 0

    WRITE(*,*) ''
    WRITE(*,*) '===================================================================='
    WRITE(*,*) 'HARNESS_Elem_Mass_Lumped: C3D8 Lumped Mass Matrix'
    WRITE(*,*) '===================================================================='
    WRITE(*,*) ''

    ! ---------------------------------------------------------------
    ! Parameters
    ! ---------------------------------------------------------------
    rho    = 7800.0_wp   ! density [kg/m^3]
    volume = 1.0_wp      ! unit cube [m^3]
    total_mass_expected = rho * volume   ! = 7800 kg
    node_mass = total_mass_expected / 8.0_wp  ! = 975 kg per node

    WRITE(*,*) '  rho    = ', rho, ' kg/m^3'
    WRITE(*,*) '  Volume = ', volume, ' m^3'
    WRITE(*,*) '  Expected total mass = ', total_mass_expected, ' kg'
    WRITE(*,*) '  Expected mass/node  = ', node_mass, ' kg'

    ! ---------------------------------------------------------------
    ! Build consistent mass matrix via 2x2x2 Gauss quadrature
    ! Me(i,j) = rho * INT N_a * N_b dV * delta_dof
    ! For unit cube: detJ = 1/8 (mapping [-1,1]^3 to [0,1]^3)
    ! ---------------------------------------------------------------

    ! 2x2x2 Gauss points in natural coords [-1,1]^3
    CALL Setup_Gauss_2x2x2(xi, w)

    M_consistent = 0.0_wp
    detJ = 1.0_wp / 8.0_wp   ! Jacobian det for unit cube (side=1, mapped from [-1,1])

    DO igp = 1, 8
      ! Evaluate trilinear shape functions at Gauss point
      CALL Eval_ShapeFunc_Hex8(xi(igp,:), N)

      wdetJ = w(igp) * detJ * rho

      ! Assemble: M(3*(a-1)+d, 3*(b-1)+d) += wdetJ * N(a) * N(b)
      DO inode = 1, 8
        DO jnode = 1, 8
          DO idof = 1, 3
            i = (inode-1)*3 + idof
            j = (jnode-1)*3 + idof
            M_consistent(i,j) = M_consistent(i,j) + wdetJ * N(inode) * N(jnode)
          END DO
        END DO
      END DO
    END DO

    ! ---------------------------------------------------------------
    ! TC-1: Consistent mass total = rho * V
    ! ---------------------------------------------------------------
    total_mass_consistent = 0.0_wp
    DO i = 1, 24
      total_mass_consistent = total_mass_consistent + M_consistent(i,i)
    END DO
    ! Note: for consistent mass, trace != total mass.
    ! Total mass = sum of any row-summed column.
    ! Actually: total mass = u^T * M * u  where u = all-ones for 1 DOF direction
    ! Let's compute: mass_x = sum_i sum_j M(i,j) for x-DOFs only
    total_mass_consistent = 0.0_wp
    DO inode = 1, 8
      DO jnode = 1, 8
        i = (inode-1)*3 + 1   ! x-DOF
        j = (jnode-1)*3 + 1
        total_mass_consistent = total_mass_consistent + M_consistent(i,j)
      END DO
    END DO

    WRITE(*,*) '  TC-1: Consistent mass conservation'
    WRITE(*,*) '    Expected = ', total_mass_expected, ' kg'
    WRITE(*,*) '    Computed = ', total_mass_consistent, ' kg'
    err = ABS(total_mass_consistent - total_mass_expected)
    WRITE(*,*) '    Abs error = ', err

    IF (err < 1.0e-4_wp) THEN
      WRITE(*,*) '    >> PASS'
      n_pass = n_pass + 1
    ELSE
      WRITE(*,*) '    >> FAIL'
      n_fail = n_fail + 1
    END IF

    ! ---------------------------------------------------------------
    ! Row-sum lumping: M_L(i) = SUM_j M_consistent(i,j)
    ! ---------------------------------------------------------------
    M_lumped = 0.0_wp
    DO i = 1, 24
      DO j = 1, 24
        M_lumped(i) = M_lumped(i) + M_consistent(i,j)
      END DO
    END DO

    ! ---------------------------------------------------------------
    ! TC-2: Lumped diagonal sum = total mass (per direction)
    ! ---------------------------------------------------------------
    total_mass_lumped = 0.0_wp
    DO inode = 1, 8
      total_mass_lumped = total_mass_lumped + M_lumped((inode-1)*3 + 1)
    END DO

    WRITE(*,*) '  TC-2: Lumped mass sum = total mass'
    WRITE(*,*) '    Expected = ', total_mass_expected, ' kg'
    WRITE(*,*) '    Lumped sum (x-dir) = ', total_mass_lumped, ' kg'
    err = ABS(total_mass_lumped - total_mass_expected)

    IF (err < 1.0e-4_wp) THEN
      WRITE(*,*) '    >> PASS'
      n_pass = n_pass + 1
    ELSE
      WRITE(*,*) '    >> FAIL'
      n_fail = n_fail + 1
    END IF

    ! ---------------------------------------------------------------
    ! TC-3: All lumped entries >= 0 (non-negative mass)
    ! ---------------------------------------------------------------
    WRITE(*,*) '  TC-3: All lumped entries >= 0'
    DO i = 1, 24
      IF (M_lumped(i) < -TOL) THEN
        WRITE(*,*) '    >> FAIL at DOF ', i, ': M_L = ', M_lumped(i)
        n_fail = n_fail + 1
        GOTO 200
      END IF
    END DO
    WRITE(*,*) '    >> PASS'
    n_pass = n_pass + 1
200 CONTINUE

    ! ---------------------------------------------------------------
    ! TC-4: Lumped mass per node = rho*V/8 = 975 kg
    ! ---------------------------------------------------------------
    WRITE(*,*) '  TC-4: Each node mass = rho*V/8'
    err = 0.0_wp
    DO inode = 1, 8
      err = MAX(err, ABS(M_lumped((inode-1)*3+1) - node_mass))
    END DO
    WRITE(*,*) '    Max |M_node - 975| = ', err

    IF (err < 1.0e-4_wp) THEN
      WRITE(*,*) '    >> PASS'
      n_pass = n_pass + 1
    ELSE
      WRITE(*,*) '    >> FAIL'
      n_fail = n_fail + 1
    END IF

    ! ---------------------------------------------------------------
    ! TC-5: x/y/z DOF masses equal (isotropic lumping)
    ! ---------------------------------------------------------------
    WRITE(*,*) '  TC-5: Isotropic lumping (x=y=z mass per node)'
    err = 0.0_wp
    DO inode = 1, 8
      i = (inode-1)*3
      err = MAX(err, ABS(M_lumped(i+1) - M_lumped(i+2)))
      err = MAX(err, ABS(M_lumped(i+2) - M_lumped(i+3)))
    END DO
    WRITE(*,*) '    Max asymmetry = ', err

    IF (err < TOL) THEN
      WRITE(*,*) '    >> PASS'
      n_pass = n_pass + 1
    ELSE
      WRITE(*,*) '    >> FAIL'
      n_fail = n_fail + 1
    END IF

    ! ---------------------------------------------------------------
    ! Summary
    ! ---------------------------------------------------------------
    WRITE(*,*) ''
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) '  HARNESS_Elem_Mass_Lumped: ', n_pass, ' PASSED, ', n_fail, ' FAILED'
    IF (n_fail == 0) THEN
      WRITE(*,*) '  >> ALL PASS'
    ELSE
      WRITE(*,*) '  >> SOME FAILURES'
    END IF
    WRITE(*,*) '===================================================================='

  END SUBROUTINE Run_Harness_Elem_Mass_Lumped

  ! ====================================================================
  ! 2x2x2 Gauss quadrature points and weights in [-1,1]^3
  ! ====================================================================
  SUBROUTINE Setup_Gauss_2x2x2(xi, w)
    REAL(wp), INTENT(OUT) :: xi(8,3), w(8)
    REAL(wp) :: g
    INTEGER(i4) :: idx, i, j, k
    REAL(wp) :: pts(2)

    g = 1.0_wp / SQRT(3.0_wp)
    pts(1) = -g;  pts(2) = g

    idx = 0
    DO k = 1, 2
      DO j = 1, 2
        DO i = 1, 2
          idx = idx + 1
          xi(idx, 1) = pts(i)
          xi(idx, 2) = pts(j)
          xi(idx, 3) = pts(k)
          w(idx) = 1.0_wp   ! each weight = 1 for 2-pt rule
        END DO
      END DO
    END DO
  END SUBROUTINE Setup_Gauss_2x2x2

  ! ====================================================================
  ! Trilinear hex shape functions at natural coords (xi, eta, zeta)
  ! ====================================================================
  SUBROUTINE Eval_ShapeFunc_Hex8(xig, N)
    REAL(wp), INTENT(IN)  :: xig(3)
    REAL(wp), INTENT(OUT) :: N(8)
    REAL(wp) :: xi, eta, zeta

    xi   = xig(1)
    eta  = xig(2)
    zeta = xig(3)

    N(1) = 0.125_wp * (1.0_wp - xi) * (1.0_wp - eta) * (1.0_wp - zeta)
    N(2) = 0.125_wp * (1.0_wp + xi) * (1.0_wp - eta) * (1.0_wp - zeta)
    N(3) = 0.125_wp * (1.0_wp + xi) * (1.0_wp + eta) * (1.0_wp - zeta)
    N(4) = 0.125_wp * (1.0_wp - xi) * (1.0_wp + eta) * (1.0_wp - zeta)
    N(5) = 0.125_wp * (1.0_wp - xi) * (1.0_wp - eta) * (1.0_wp + zeta)
    N(6) = 0.125_wp * (1.0_wp + xi) * (1.0_wp - eta) * (1.0_wp + zeta)
    N(7) = 0.125_wp * (1.0_wp + xi) * (1.0_wp + eta) * (1.0_wp + zeta)
    N(8) = 0.125_wp * (1.0_wp - xi) * (1.0_wp + eta) * (1.0_wp + zeta)
  END SUBROUTINE Eval_ShapeFunc_Hex8

END MODULE HARNESS_Elem_Mass_Lumped

!===============================================================================
! Runner
!===============================================================================
PROGRAM HARNESS_Elem_Mass_Lumped_Runner
  USE HARNESS_Elem_Mass_Lumped, ONLY: Run_Harness_Elem_Mass_Lumped
  IMPLICIT NONE
  CALL Run_Harness_Elem_Mass_Lumped()
END PROGRAM HARNESS_Elem_Mass_Lumped_Runner
