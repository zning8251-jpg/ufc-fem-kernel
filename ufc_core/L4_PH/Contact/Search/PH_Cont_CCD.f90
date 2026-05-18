!===============================================================================
! MODULE: PH_Cont_CCD
! LAYER:  L4_PH
! DOMAIN: Contact / Search
! ROLE:   Core
! BRIEF:  Continuous Collision Detection (CCD) for fast-moving bodies
!
! Theory: Swept Volume, Time-of-Impact (TOI), Conservative Advancement
!   Wriggers §11.3; Ericson §5.3; Redon et al. (2002)
! Contract: L4_PH/Contact/CONTRACT.md
! Status: ACTIVE | Last verified: 2026-04-28
!===============================================================================
MODULE PH_Cont_CCD
  USE IF_Base_Def, ONLY: ZERO, ONE, TWO, HALF, SMALL_VAL => SMALL
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  
  IMPLICIT NONE
  PRIVATE
  
  ! Parameters
  INTEGER(i4), PARAMETER :: PH_ContCCD_MAX_ITER = 50_i4
  REAL(wp), PARAMETER :: PH_ContCCD_TOL_TOI = 1.0e-8_wp
  REAL(wp), PARAMETER :: PH_ContCCD_MIN_DT = 1.0e-12_wp
  
  ! ===================================================================
  ! Public Types
  ! ===================================================================
  PUBLIC :: PH_ContCCD_Trajectory
  PUBLIC :: PH_ContCCD_SweptVolume
  PUBLIC :: PH_ContCCD_TOIResult
  
  ! ===================================================================
  ! Public Interfaces
  ! ===================================================================
  PUBLIC :: PH_ContCCD_ComputeTOI
  PUBLIC :: PH_ContCCD_SweptSphere
  PUBLIC :: PH_ContCCD_ConservativeAdvancement
  PUBLIC :: PH_ContCCD_BinarySearch
  PUBLIC :: PH_ContCCD_NewtonRaphson
  PUBLIC :: PH_ContCCD_Detect_EdgeEdge
  PUBLIC :: PH_ContCCD_Detect_PointTriangle
  
  ! ===================================================================
  ! Type Definitions
  ! ===================================================================
  
  TYPE :: PH_ContCCD_Trajectory
    ! Quadratic trajectory: x(t) = x0 + v0*t + 0.5*a*t^2
    REAL(wp) :: x0(3)      ! Initial position
    REAL(wp) :: v0(3)      ! Initial velocity
    REAL(wp) :: a(3)       ! Acceleration (constant)
    REAL(wp) :: dt         ! Time step
  CONTAINS
    PROCEDURE :: Position => Trajectory_Position
    PROCEDURE :: Velocity => Trajectory_Velocity
  END TYPE PH_ContCCD_Trajectory
  
  TYPE :: PH_ContCCD_SweptVolume
    ! Bounding volume swept along trajectory
    REAL(wp) :: bbox_min(3)  ! Swept bounding box min
    REAL(wp) :: bbox_max(3)  ! Swept bounding box max
    REAL(wp) :: radius       ! Sphere radius (if applicable)
    LOGICAL :: is_valid      ! Volume validity flag
  END TYPE PH_ContCCD_SweptVolume
  
  TYPE :: PH_ContCCD_TOIResult
    ! Time of Impact result
    REAL(wp) :: toi          ! Time of impact [0, dt]
    REAL(wp) :: gap          ! Gap at TOI
    REAL(wp) :: normal(3)    ! Contact normal at TOI
    REAL(wp) :: point(3)     ! Contact point at TOI
    LOGICAL :: impacted      ! Impact detected flag
    INTEGER(i4) :: iterations ! Newton iterations used
  END TYPE PH_ContCCD_TOIResult
  
CONTAINS

  ! ===========================================================================
  ! Trajectory Methods
  ! ===========================================================================
  
  FUNCTION Trajectory_Position(this, t) RESULT(x)
    CLASS(PH_ContCCD_Trajectory), INTENT(IN) :: this
    REAL(wp), INTENT(IN) :: t
    REAL(wp) :: x(3)
    
    x = this%x0 + this%v0 * t + HALF * this%a * t * t
  END FUNCTION Trajectory_Position
  
  FUNCTION Trajectory_Velocity(this, t) RESULT(v)
    CLASS(PH_ContCCD_Trajectory), INTENT(IN) :: this
    REAL(wp), INTENT(IN) :: t
    REAL(wp) :: v(3)
    
    v = this%v0 + this%a * t
  END FUNCTION Trajectory_Velocity
  
  ! ===========================================================================
  ! Core CCD Algorithms
  ! ===========================================================================
  
  SUBROUTINE PH_ContCCD_ComputeTOI(traj1, traj2, radius1, radius2, &
                                   result, status)
    !> Compute Time of Impact between two moving spheres
    TYPE(PH_ContCCD_Trajectory), INTENT(IN) :: traj1, traj2
    REAL(wp), INTENT(IN) :: radius1, radius2
    TYPE(PH_ContCCD_TOIResult), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    REAL(wp) :: t_low, t_high, t_mid
    REAL(wp) :: dist, gap, vel_rel
    INTEGER(i4) :: iter
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    ! Initialize result
    result%toi = ZERO
    result%gap = ZERO
    result%normal = ZERO
    result%point = ZERO
    result%impacted = .FALSE.
    result%iterations = 0_i4
    
    ! Check initial configuration
    dist = SQRT(SUM((traj1%x0 - traj2%x0)**2))
    gap = dist - (radius1 + radius2)
    
    ! No collision if initially separated and moving apart
    vel_rel = DOT_PRODUCT(traj1%v0 - traj2%v0, traj1%x0 - traj2%x0) / dist
    IF (gap > ZERO .AND. vel_rel >= ZERO) THEN
      result%gap = gap
      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
      RETURN
    END IF
    
    ! Binary search for TOI
    t_low = ZERO
    t_high = traj1%dt
    result%impacted = .FALSE.
    
    DO iter = 1, PH_ContCCD_MAX_ITER
      t_mid = HALF * (t_low + t_high)
      
      ! Compute positions at t_mid
      CALL EvaluateGap(traj1, traj2, radius1, radius2, t_mid, gap)
      
      IF (ABS(gap) < PH_ContCCD_TOL_TOI) THEN
        result%impacted = .TRUE.
        EXIT
      ELSE IF (gap > ZERO) THEN
        t_low = t_mid
      ELSE
        t_high = t_mid
      END IF
      
      ! Check convergence
      IF (t_high - t_low < PH_ContCCD_TOL_TOI) THEN
        result%impacted = (gap <= ZERO)
        EXIT
      END IF
    END DO
    
    result%toi = t_mid
    result%gap = gap
    result%iterations = iter
    
    ! Compute contact normal and point at TOI
    IF (result%impacted) THEN
      CALL ComputeContactData(traj1, traj2, t_mid, result%normal, result%point)
    END IF
    
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_ContCCD_ComputeTOI
  
  ! ===========================================================================
  ! Swept Volume Computation
  ! ===========================================================================
  
  SUBROUTINE PH_ContCCD_SweptSphere(center0, center1, radius, volume, status)
    !> Compute swept volume of a moving sphere
    REAL(wp), INTENT(IN) :: center0(3), center1(3)
    REAL(wp), INTENT(IN) :: radius
    TYPE(PH_ContCCD_SweptVolume), INTENT(OUT) :: volume
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    INTEGER(i4) :: i
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    ! Swept AABB = union of start and end spheres
    DO i = 1, 3
      volume%bbox_min(i) = MIN(center0(i), center1(i)) - radius
      volume%bbox_max(i) = MAX(center0(i), center1(i)) + radius
    END DO
    
    volume%radius = radius
    volume%is_valid = .TRUE.
    
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_ContCCD_SweptSphere
  
  ! ===========================================================================
  ! Conservative Advancement
  ! ===========================================================================
  
  SUBROUTINE PH_ContCCD_ConservativeAdvancement(dist, vel_rel, dt_max, &
                                                dt_safe, status)
    !> Compute conservative safe time step to avoid tunneling
    REAL(wp), INTENT(IN) :: dist, vel_rel, dt_max
    REAL(wp), INTENT(OUT) :: dt_safe
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    ! CFL-like condition: dt_safe = dist / |vel_rel|
    IF (ABS(vel_rel) > SMALL_VAL) THEN
      dt_safe = MIN(dist / ABS(vel_rel), dt_max)
    ELSE
      dt_safe = dt_max
    END IF
    
    ! Safety factor (typically 0.5-0.9)
    dt_safe = 0.9_wp * dt_safe
    
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_ContCCD_ConservativeAdvancement
  
  ! ===========================================================================
  ! Binary Search for TOI
  ! ===========================================================================
  
  SUBROUTINE PH_ContCCD_BinarySearch(traj1, traj2, radius1, radius2, &
                                     t0, t1, tol, toi, gap, iter, status)
    !> Binary search refinement for TOI
    TYPE(PH_ContCCD_Trajectory), INTENT(IN) :: traj1, traj2
    REAL(wp), INTENT(IN) :: radius1, radius2, t0, t1, tol
    REAL(wp), INTENT(OUT) :: toi, gap
    INTEGER(i4), INTENT(OUT) :: iter
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    REAL(wp) :: t_mid, gap_mid
    INTEGER(i4) :: max_iter
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    max_iter = PH_ContCCD_MAX_ITER
    toi = ZERO
    gap = ZERO
    iter = 0_i4
    
    DO iter = 1, max_iter
      t_mid = HALF * (t0 + t1)
      
      CALL EvaluateGap(traj1, traj2, radius1, radius2, t_mid, gap_mid)
      
      IF (ABS(gap_mid) < tol) THEN
        toi = t_mid
        gap = gap_mid
        EXIT
      ELSE IF (gap_mid > ZERO) THEN
        t0 = t_mid
      ELSE
        t1 = t_mid
      END IF
      
      ! Check interval size
      IF (t1 - t0 < tol) THEN
        toi = t_mid
        gap = gap_mid
        EXIT
      END IF
    END DO
    
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_ContCCD_BinarySearch
  
  ! ===========================================================================
  ! Newton-Raphson for TOI
  ! ===========================================================================
  
  SUBROUTINE PH_ContCCD_NewtonRaphson(traj1, traj2, radius1, radius2, &
                                      t_init, tol, toi, gap, iter, converged, status)
    !> Newton-Raphson iteration for TOI (faster convergence)
    TYPE(PH_ContCCD_Trajectory), INTENT(IN) :: traj1, traj2
    REAL(wp), INTENT(IN) :: radius1, radius2, t_init, tol
    REAL(wp), INTENT(OUT) :: toi, gap
    INTEGER(i4), INTENT(OUT) :: iter
    LOGICAL, INTENT(OUT) :: converged
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    REAL(wp) :: t_curr, f_val, f_deriv, dt_update
    INTEGER(i4) :: max_iter
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    t_curr = t_init
    converged = .FALSE.
    max_iter = PH_ContCCD_MAX_ITER
    
    DO iter = 1, max_iter
      ! Evaluate gap function: f(t) = |x1(t) - x2(t)| - (r1 + r2)
      CALL EvaluateGapAndDeriv(traj1, traj2, radius1, radius2, t_curr, &
                               f_val, f_deriv)
      
      gap = f_val
      toi = t_curr
      
      ! Check convergence
      IF (ABS(f_val) < tol) THEN
        converged = .TRUE.
        EXIT
      END IF
      
      ! Newton update: t_{k+1} = t_k - f(t_k) / f'(t_k)
      IF (ABS(f_deriv) > SMALL_VAL) THEN
        dt_update = f_val / f_deriv
        t_curr = t_curr - dt_update
        
        ! Clamp to [0, dt]
        t_curr = MAX(ZERO, MIN(traj1%dt, t_curr))
      ELSE
        ! Derivative too small, fall back to bisection
        EXIT
      END IF
    END DO
    
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_ContCCD_NewtonRaphson
  
  ! ===========================================================================
  ! Helper Functions
  ! ===========================================================================
  
  ! ===========================================================================
  ! Edge-Edge Continuous Collision Detection
  ! ===========================================================================

  SUBROUTINE PH_ContCCD_Detect_EdgeEdge(edge1_p0, edge1_p1, edge2_p0, edge2_p1, &
                                         vel1_p0, vel1_p1, vel2_p0, vel2_p1, &
                                         dt, toc, detected, status)
    !> Edge-edge CCD: find earliest time t in [0,dt] when two moving edges
    !> become coplanar and intersect.
    !> Theory: The coplanarity condition is a cubic polynomial in t:
    !>   f(t) = (e1(t) x e2(t)) . d(t) = 0
    !> where e1,e2 are edge vectors and d is the vector between edge origins.
    REAL(wp), INTENT(IN)  :: edge1_p0(3), edge1_p1(3)  ! Edge 1 endpoints at t=0
    REAL(wp), INTENT(IN)  :: edge2_p0(3), edge2_p1(3)  ! Edge 2 endpoints at t=0
    REAL(wp), INTENT(IN)  :: vel1_p0(3), vel1_p1(3)    ! Velocities of edge 1 endpoints
    REAL(wp), INTENT(IN)  :: vel2_p0(3), vel2_p1(3)    ! Velocities of edge 2 endpoints
    REAL(wp), INTENT(IN)  :: dt                         ! Time step
    REAL(wp), INTENT(OUT) :: toc                        ! Time of contact
    LOGICAL,  INTENT(OUT) :: detected                   ! Contact detected flag
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    REAL(wp) :: a0(3), a1(3), b0(3), b1(3), d0(3), d1(3)
    REAL(wp) :: cross_ab0(3), cross_ab1(3), cross_a0b1(3), cross_a1b0(3)
    REAL(wp) :: c3, c2, c1, c0
    REAL(wp) :: t_test, f_val, s, u
    REAL(wp) :: e1(3), e2(3), d_vec(3), cross_e(3), norm_cross
    INTEGER(i4) :: i_step, n_steps

    IF (PRESENT(status)) CALL init_error_status(status)
    detected = .FALSE.
    toc = dt

    ! Edge vectors at t=0 and their rates of change
    ! Edge 1: from edge1_p0 to edge1_p1
    ! a(t) = a0 + a1*t  where a0 = edge1_p1 - edge1_p0, a1 = vel1_p1 - vel1_p0
    a0 = edge1_p1 - edge1_p0
    a1 = vel1_p1  - vel1_p0

    ! Edge 2: from edge2_p0 to edge2_p1
    b0 = edge2_p1 - edge2_p0
    b1 = vel2_p1  - vel2_p0

    ! d(t) = edge2_p0(t) - edge1_p0(t)
    d0 = edge2_p0 - edge1_p0
    d1 = vel2_p0  - vel1_p0

    ! Coplanarity: f(t) = (a(t) x b(t)) . d(t) = 0
    ! This is a cubic in t. We use interval sampling + bisection.
    ! Evaluate f(t) at uniform samples to find sign changes, then refine.
    n_steps = 100_i4

    c0 = TripleProduct(a0, b0, d0)  ! f(0)

    DO i_step = 1, n_steps
      t_test = dt * REAL(i_step, wp) / REAL(n_steps, wp)

      ! Compute a(t), b(t), d(t)
      e1 = a0 + a1 * t_test
      e2 = b0 + b1 * t_test
      d_vec = d0 + d1 * t_test

      f_val = TripleProduct(e1, e2, d_vec)

      ! Sign change → root in [t_prev, t_test]
      IF (c0 * f_val < ZERO) THEN
        ! Bisection refinement
        CALL BisectCubicRoot(a0, a1, b0, b1, d0, d1, &
                             t_test - dt/REAL(n_steps,wp), t_test, &
                             PH_ContCCD_TOL_TOI, toc)

        ! Validate: check edge parameters s,u in [0,1]
        e1 = a0 + a1 * toc
        e2 = b0 + b1 * toc
        d_vec = d0 + d1 * toc
        cross_e(1) = e1(2)*e2(3) - e1(3)*e2(2)
        cross_e(2) = e1(3)*e2(1) - e1(1)*e2(3)
        cross_e(3) = e1(1)*e2(2) - e1(2)*e2(1)
        norm_cross = DOT_PRODUCT(cross_e, cross_e)
        IF (norm_cross > SMALL_VAL**2) THEN
          ! Solve for s,u using least-squares
          s = DOT_PRODUCT(d_vec, e1) / DOT_PRODUCT(e1, e1)
          u = -DOT_PRODUCT(d_vec, e2) / DOT_PRODUCT(e2, e2)
          IF (s >= -0.01_wp .AND. s <= 1.01_wp .AND. &
              u >= -0.01_wp .AND. u <= 1.01_wp) THEN
            detected = .TRUE.
            IF (PRESENT(status)) status%status_code = IF_STATUS_OK
            RETURN
          END IF
        END IF
      END IF
      c0 = f_val
    END DO

    toc = dt  ! No contact found
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_ContCCD_Detect_EdgeEdge

  ! ===========================================================================
  ! Point-Triangle Continuous Collision Detection
  ! ===========================================================================

  SUBROUTINE PH_ContCCD_Detect_PointTriangle(point, tri1, tri2, tri3, &
                                              vel_p, vel_t1, vel_t2, vel_t3, &
                                              dt, toc, detected, status)
    !> Point-triangle CCD: find earliest time t in [0,dt] when a moving point
    !> passes through a moving triangle.
    !> Theory: Coplanarity condition (cubic in t):
    !>   f(t) = ((p(t)-t1(t)) x (t2(t)-t1(t))) . (t3(t)-t1(t)) = 0
    REAL(wp), INTENT(IN)  :: point(3)             ! Point position at t=0
    REAL(wp), INTENT(IN)  :: tri1(3), tri2(3), tri3(3)  ! Triangle vertices at t=0
    REAL(wp), INTENT(IN)  :: vel_p(3)             ! Point velocity
    REAL(wp), INTENT(IN)  :: vel_t1(3), vel_t2(3), vel_t3(3)  ! Triangle velocities
    REAL(wp), INTENT(IN)  :: dt                   ! Time step
    REAL(wp), INTENT(OUT) :: toc                  ! Time of contact
    LOGICAL,  INTENT(OUT) :: detected             ! Contact detected flag
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    REAL(wp) :: d0(3), d1(3), e10(3), e11(3), e20(3), e21(3)
    REAL(wp) :: d_t(3), e1_t(3), e2_t(3)
    REAL(wp) :: f_val, f_prev
    REAL(wp) :: t_test, t_prev
    REAL(wp) :: cross_t(3), norm_cross, u, v, w
    INTEGER(i4) :: i_step, n_steps

    IF (PRESENT(status)) CALL init_error_status(status)
    detected = .FALSE.
    toc = dt

    ! d(t) = point(t) - tri1(t)
    d0 = point - tri1
    d1 = vel_p - vel_t1

    ! e1(t) = tri2(t) - tri1(t)
    e10 = tri2 - tri1
    e11 = vel_t2 - vel_t1

    ! e2(t) = tri3(t) - tri1(t)
    e20 = tri3 - tri1
    e21 = vel_t3 - vel_t1

    ! Coplanarity: f(t) = d(t) . (e1(t) x e2(t)) = 0 (cubic)
    n_steps = 100_i4
    f_prev = TripleProduct(d0, e10, e20)
    t_prev = ZERO

    DO i_step = 1, n_steps
      t_test = dt * REAL(i_step, wp) / REAL(n_steps, wp)

      d_t  = d0  + d1  * t_test
      e1_t = e10 + e11 * t_test
      e2_t = e20 + e21 * t_test

      f_val = TripleProduct(d_t, e1_t, e2_t)

      IF (f_prev * f_val < ZERO) THEN
        ! Sign change — refine via bisection
        CALL BisectTripleRoot(d0, d1, e10, e11, e20, e21, &
                              t_prev, t_test, PH_ContCCD_TOL_TOI, toc)

        ! Validate: check barycentric coords
        d_t  = d0  + d1  * toc
        e1_t = e10 + e11 * toc
        e2_t = e20 + e21 * toc

        ! Point-in-triangle test via barycentric coordinates
        cross_t(1) = e1_t(2)*e2_t(3) - e1_t(3)*e2_t(2)
        cross_t(2) = e1_t(3)*e2_t(1) - e1_t(1)*e2_t(3)
        cross_t(3) = e1_t(1)*e2_t(2) - e1_t(2)*e2_t(1)
        norm_cross = DOT_PRODUCT(cross_t, cross_t)

        IF (norm_cross > SMALL_VAL**2) THEN
          ! Barycentric: d_t = u*e1_t + v*e2_t
          u = (DOT_PRODUCT(d_t, e1_t)*DOT_PRODUCT(e2_t,e2_t) - &
               DOT_PRODUCT(d_t, e2_t)*DOT_PRODUCT(e1_t,e2_t)) / norm_cross
          v = (DOT_PRODUCT(d_t, e2_t)*DOT_PRODUCT(e1_t,e1_t) - &
               DOT_PRODUCT(d_t, e1_t)*DOT_PRODUCT(e1_t,e2_t)) / norm_cross
          w = 1.0_wp - u - v

          IF (u >= -0.01_wp .AND. v >= -0.01_wp .AND. w >= -0.01_wp) THEN
            detected = .TRUE.
            IF (PRESENT(status)) status%status_code = IF_STATUS_OK
            RETURN
          END IF
        END IF
      END IF

      f_prev = f_val
      t_prev = t_test
    END DO

    toc = dt
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_ContCCD_Detect_PointTriangle

  ! ===========================================================================
  ! Helper Functions
  ! ===========================================================================

  PURE FUNCTION TripleProduct(a, b, c) RESULT(tp)
    !> Scalar triple product: a . (b x c)
    REAL(wp), INTENT(IN) :: a(3), b(3), c(3)
    REAL(wp) :: tp
    tp = a(1)*(b(2)*c(3) - b(3)*c(2)) &
       + a(2)*(b(3)*c(1) - b(1)*c(3)) &
       + a(3)*(b(1)*c(2) - b(2)*c(1))
  END FUNCTION TripleProduct

  SUBROUTINE BisectCubicRoot(a0, a1, b0, b1, d0, d1, t_lo, t_hi, tol, t_root)
    !> Bisection to find root of coplanarity function for edge-edge
    REAL(wp), INTENT(IN) :: a0(3), a1(3), b0(3), b1(3), d0(3), d1(3)
    REAL(wp), INTENT(IN) :: t_lo, t_hi, tol
    REAL(wp), INTENT(OUT) :: t_root
    REAL(wp) :: tl, th, tm, fl, fm
    REAL(wp) :: e1(3), e2(3), dv(3)
    INTEGER(i4) :: iter
    tl = t_lo;  th = t_hi
    e1 = a0 + a1*tl;  e2 = b0 + b1*tl;  dv = d0 + d1*tl
    fl = TripleProduct(e1, e2, dv)
    DO iter = 1, PH_ContCCD_MAX_ITER
      tm = HALF * (tl + th)
      e1 = a0 + a1*tm;  e2 = b0 + b1*tm;  dv = d0 + d1*tm
      fm = TripleProduct(e1, e2, dv)
      IF (ABS(fm) < tol .OR. (th - tl) < tol) EXIT
      IF (fl * fm < ZERO) THEN
        th = tm
      ELSE
        tl = tm;  fl = fm
      END IF
    END DO
    t_root = tm
  END SUBROUTINE BisectCubicRoot

  SUBROUTINE BisectTripleRoot(d0, d1, e10, e11, e20, e21, t_lo, t_hi, tol, t_root)
    !> Bisection to find root of coplanarity function for point-triangle
    REAL(wp), INTENT(IN) :: d0(3), d1(3), e10(3), e11(3), e20(3), e21(3)
    REAL(wp), INTENT(IN) :: t_lo, t_hi, tol
    REAL(wp), INTENT(OUT) :: t_root
    REAL(wp) :: tl, th, tm, fl, fm
    REAL(wp) :: dv(3), ev1(3), ev2(3)
    INTEGER(i4) :: iter
    tl = t_lo;  th = t_hi
    dv = d0 + d1*tl;  ev1 = e10 + e11*tl;  ev2 = e20 + e21*tl
    fl = TripleProduct(dv, ev1, ev2)
    DO iter = 1, PH_ContCCD_MAX_ITER
      tm = HALF * (tl + th)
      dv = d0 + d1*tm;  ev1 = e10 + e11*tm;  ev2 = e20 + e21*tm
      fm = TripleProduct(dv, ev1, ev2)
      IF (ABS(fm) < tol .OR. (th - tl) < tol) EXIT
      IF (fl * fm < ZERO) THEN
        th = tm
      ELSE
        tl = tm;  fl = fm
      END IF
    END DO
    t_root = tm
  END SUBROUTINE BisectTripleRoot

  SUBROUTINE EvaluateGap(traj1, traj2, radius1, radius2, t, gap)
    !> Evaluate gap function at time t
    TYPE(PH_ContCCD_Trajectory), INTENT(IN) :: traj1, traj2
    REAL(wp), INTENT(IN) :: radius1, radius2, t
    REAL(wp), INTENT(OUT) :: gap
    
    REAL(wp) :: x1(3), x2(3), dist
    
    ! Positions at time t
    x1 = traj1%x0 + traj1%v0 * t + HALF * traj1%a * t * t
    x2 = traj2%x0 + traj2%v0 * t + HALF * traj2%a * t * t
    
    ! Distance
    dist = SQRT(SUM((x1 - x2)**2))
    
    ! Gap
    gap = dist - (radius1 + radius2)
  END SUBROUTINE EvaluateGap
  
  SUBROUTINE EvaluateGapAndDeriv(traj1, traj2, radius1, radius2, t, gap, deriv)
    !> Evaluate gap and its derivative at time t
    TYPE(PH_ContCCD_Trajectory), INTENT(IN) :: traj1, traj2
    REAL(wp), INTENT(IN) :: radius1, radius2, t
    REAL(wp), INTENT(OUT) :: gap, deriv
    
    REAL(wp) :: x1(3), x2(3), v1(3), v2(3), dx(3), dv(3)
    REAL(wp) :: dist, dist_sq
    
    ! Positions and velocities at time t
    x1 = traj1%x0 + traj1%v0 * t + HALF * traj1%a * t * t
    x2 = traj2%x0 + traj2%v0 * t + HALF * traj2%a * t * t
    v1 = traj1%v0 + traj1%a * t
    v2 = traj2%v0 + traj2%a * t
    
    ! Relative quantities
    dx = x1 - x2
    dv = v1 - v2
    dist_sq = DOT_PRODUCT(dx, dx)
    dist = SQRT(dist_sq)
    
    ! Gap
    gap = dist - (radius1 + radius2)
    
    ! Derivative: d/dt gap = (dx · dv) / |dx|
    IF (dist > SMALL_VAL) THEN
      deriv = DOT_PRODUCT(dx, dv) / dist
    ELSE
      deriv = ZERO
    END IF
  END SUBROUTINE EvaluateGapAndDeriv
  
  PURE SUBROUTINE ComputeContactData(traj1, traj2, t, normal, point)
    !> Compute contact normal and point at time t
    TYPE(PH_ContCCD_Trajectory), INTENT(IN) :: traj1, traj2
    REAL(wp), INTENT(IN) :: t
    REAL(wp), INTENT(OUT) :: normal(3), point(3)
    
    REAL(wp) :: x1(3), x2(3), dist
    
    ! Positions at time t
    x1 = traj1%x0 + traj1%v0 * t + HALF * traj1%a * t * t
    x2 = traj2%x0 + traj2%v0 * t + HALF * traj2%a * t * t
    
    ! Normal (from 2 to 1)
    dist = SQRT(SUM((x1 - x2)**2))
    IF (dist > SMALL_VAL) THEN
      normal = (x1 - x2) / dist
    ELSE
      normal = ZERO
    END IF
    
    ! Contact point (midpoint)
    point = HALF * (x1 + x2)
  END SUBROUTINE ComputeContactData
  
END MODULE PH_Cont_CCD