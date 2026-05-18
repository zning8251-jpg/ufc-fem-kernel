!===============================================================================
! MODULE: PH_Elem_GaussInt
! LAYER:  L4_PH
! DOMAIN: Element
! ROLE:   Proc
! BRIEF:  Gauss quadrature rule initialization for element integration
! **W2**：**`PH_Elem_GaussInt_Desc`** 承载积分点规则；与 **`PH_Elem_Core`** / 族核 IP 循环一致。
!===============================================================================
MODULE PH_Elem_GaussInt
  USE IF_Prec_Core, ONLY: wp, i4
  
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: PH_Elem_GaussInt_Desc
  ! Legacy alias GaussRule removed — all references migrated to PH_Elem_GaussInt_Desc
  
  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_GaussInt_Desc
  ! KIND: Desc
  ! DESC: Gaussian quadrature rule (points + weights).
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Elem_GaussInt_Desc
    INTEGER(i4) :: dim = 0              ! Dimension (1, 2, or 3)
    INTEGER(i4) :: order = 0            ! Integration order
    INTEGER(i4) :: n_points = 0         ! Number of Gauss points
    
    REAL(wp), ALLOCATABLE :: xi(:,:)    ! Gauss point coordinates [n_points, dim]
    REAL(wp), ALLOCATABLE :: w(:)       ! Gauss point weights [n_points]
    
  CONTAINS
    PROCEDURE, PASS(this) :: Init1D => InitGauss1D
    PROCEDURE, PASS(this) :: Init2D => InitGauss2D_Quad
    PROCEDURE, PASS(this) :: Init3D => InitGauss3D_Hex
    PROCEDURE, PASS(this) :: GetFaceRule => GetHexFaceGauss
    PROCEDURE, PASS(this) :: GetEdgeRule => GetQuadEdgeGauss
  END TYPE PH_Elem_GaussInt_Desc
  
    !--- Legacy alias removed — use PH_Elem_GaussInt_Desc directly ---

CONTAINS

  !=============================================================================
  ! Subroutine: InitGauss1D
  ! Purpose: Initialize 1D Gauss-Legendre quadrature rule
  !=============================================================================
  SUBROUTINE InitGauss1D(this, order)
    CLASS(PH_Elem_GaussInt_Desc), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: order
    
    REAL(wp), PARAMETER :: SQRT3 = 1.7320508075688772935274463415059_wp
    REAL(wp), PARAMETER :: SQRT15 = 3.8729833462074168851792653997824_wp
    
    this%dim = 1
    this%order = order
    
    SELECT CASE(order)
      CASE(1)  ! 1-point Gauss rule (exact for linear polynomials)
        this%n_points = 1
        ALLOCATE(this%xi(1,1), this%w(1))
        this%xi(1,1) = 0.0_wp
        this%w(1) = 2.0_wp
        
      CASE(2)  ! 2-point Gauss rule (exact for cubic polynomials)
        this%n_points = 2
        ALLOCATE(this%xi(2,1), this%w(2))
        this%xi(:,1) = [-1.0_wp/SQRT3, 1.0_wp/SQRT3]
        this%w(:) = [1.0_wp, 1.0_wp]
        
      CASE(3)  ! 3-point Gauss rule (exact for quintic polynomials)
        this%n_points = 3
        ALLOCATE(this%xi(3,1), this%w(3))
        this%xi(:,1) = [-SQRT(3.0_wp/5.0_wp), 0.0_wp, SQRT(3.0_wp/5.0_wp)]
        this%w(:) = [5.0_wp/9.0_wp, 8.0_wp/9.0_wp, 5.0_wp/9.0_wp]
        
      CASE DEFAULT
        WRITE(*,*) "Unsupported 1D Gauss order:", order
        ERROR STOP "Invalid Gauss integration order"
    END SELECT
  END SUBROUTINE InitGauss1D

  !=============================================================================
  ! Subroutine: InitGauss2D_Quad
  ! Purpose: Initialize 2D Gauss rule for quadrilateral elements via tensor product
  !=============================================================================
  SUBROUTINE InitGauss2D_Quad(this, order)
    CLASS(PH_Elem_GaussInt_Desc), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: order
    
    TYPE(PH_Elem_GaussInt_Desc) :: gauss1d
    INTEGER(i4) :: i, j, ip
    
    this%dim = 2
    this%order = order
    
    ! Create 1D rule and take tensor product
    CALL InitGauss1D(gauss1d, order)
    this%n_points = gauss1d%n_points ** 2
    
    ALLOCATE(this%xi(this%n_points, 2), this%w(this%n_points))
    
    ip = 1
    DO i = 1, gauss1d%n_points
      DO j = 1, gauss1d%n_points
        this%xi(ip,:) = [gauss1d%xi(j,1), gauss1d%xi(i,1)]
        this%w(ip) = gauss1d%w(j) * gauss1d%w(i)
        ip = ip + 1
      END DO
    END DO
    
    DEALLOCATE(gauss1d%xi, gauss1d%w)
  END SUBROUTINE InitGauss2D_Quad

  !=============================================================================
  ! Subroutine: InitGauss3D_Hex
  ! Purpose: Initialize 3D Gauss rule for hexahedral elements via tensor product
  !=============================================================================
  SUBROUTINE InitGauss3D_Hex(this, order)
    CLASS(PH_Elem_GaussInt_Desc), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: order
    
    TYPE(PH_Elem_GaussInt_Desc) :: gauss1d
    INTEGER(i4) :: i, j, k, ip
    
    this%dim = 3
    this%order = order
    
    ! Create 1D rule and take tensor product
    CALL InitGauss1D(gauss1d, order)
    this%n_points = gauss1d%n_points ** 3
    
    ALLOCATE(this%xi(this%n_points, 3), this%w(this%n_points))
    
    ip = 1
    DO i = 1, gauss1d%n_points
      DO j = 1, gauss1d%n_points
        DO k = 1, gauss1d%n_points
          this%xi(ip,:) = [gauss1d%xi(k,1), gauss1d%xi(j,1), gauss1d%xi(i,1)]
          this%w(ip) = gauss1d%w(k) * gauss1d%w(j) * gauss1d%w(i)
          ip = ip + 1
        END DO
      END DO
    END DO
    
    DEALLOCATE(gauss1d%xi, gauss1d%w)
  END SUBROUTINE InitGauss3D_Hex

  !=============================================================================
  ! Subroutine: GetHexFaceGauss
  ! Purpose: Get Gauss points on a specific face of a hexahedral element
  !=============================================================================
  SUBROUTINE GetHexFaceGauss(this, face_id, order, face_gauss)
    CLASS(PH_Elem_GaussInt_Desc), INTENT(IN) :: this
    INTEGER(i4), INTENT(IN) :: face_id    ! Face number (1-6)
    INTEGER(i4), INTENT(IN) :: order      ! Integration order
    TYPE(PH_Elem_GaussInt_Desc), INTENT(INOUT) :: face_gauss
    
    TYPE(PH_Elem_GaussInt_Desc) :: gauss2d
    INTEGER(i4) :: i
    
    CALL InitGauss2D_Quad(gauss2d, order)
    face_gauss%dim = 3
    face_gauss%order = order
    face_gauss%n_points = gauss2d%n_points
    
    ALLOCATE(face_gauss%xi(face_gauss%n_points, 3), face_gauss%w(face_gauss%n_points))
    face_gauss%w = gauss2d%w
    
    SELECT CASE(face_id)
      CASE(1)  ! Face ξ = -1
        DO i = 1, face_gauss%n_points
          face_gauss%xi(i,:) = [-1.0_wp, gauss2d%xi(i,1), gauss2d%xi(i,2)]
        END DO
      CASE(2)  ! Face ξ = +1
        DO i = 1, face_gauss%n_points
          face_gauss%xi(i,:) = [1.0_wp, gauss2d%xi(i,1), gauss2d%xi(i,2)]
        END DO
      CASE(3)  ! Face η = -1
        DO i = 1, face_gauss%n_points
          face_gauss%xi(i,:) = [gauss2d%xi(i,1), -1.0_wp, gauss2d%xi(i,2)]
        END DO
      CASE(4)  ! Face η = +1
        DO i = 1, face_gauss%n_points
          face_gauss%xi(i,:) = [gauss2d%xi(i,1), 1.0_wp, gauss2d%xi(i,2)]
        END DO
      CASE(5)  ! Face ζ = -1
        DO i = 1, face_gauss%n_points
          face_gauss%xi(i,:) = [gauss2d%xi(i,1), gauss2d%xi(i,2), -1.0_wp]
        END DO
      CASE(6)  ! Face ζ = +1
        DO i = 1, face_gauss%n_points
          face_gauss%xi(i,:) = [gauss2d%xi(i,1), gauss2d%xi(i,2), 1.0_wp]
        END DO
      CASE DEFAULT
        WRITE(*,*) "Hexahedron face ID must be 1-6, got:", face_id
        ERROR STOP "Invalid face ID"
    END SELECT
    
    DEALLOCATE(gauss2d%xi, gauss2d%w)
  END SUBROUTINE GetHexFaceGauss

  !=============================================================================
  ! Subroutine: GetQuadEdgeGauss
  ! Purpose: Get Gauss points on a specific edge of a quadrilateral element
  !=============================================================================
  SUBROUTINE GetQuadEdgeGauss(this, edge_id, order, edge_gauss)
    CLASS(PH_Elem_GaussInt_Desc), INTENT(IN) :: this
    INTEGER(i4), INTENT(IN) :: edge_id    ! Edge number (1-4)
    INTEGER(i4), INTENT(IN) :: order      ! Integration order
    TYPE(PH_Elem_GaussInt_Desc), INTENT(INOUT) :: edge_gauss
    
    TYPE(PH_Elem_GaussInt_Desc) :: gauss1d
    INTEGER(i4) :: i
    
    CALL InitGauss1D(gauss1d, order)
    edge_gauss%dim = 2
    edge_gauss%order = order
    edge_gauss%n_points = gauss1d%n_points
    
    ALLOCATE(edge_gauss%xi(edge_gauss%n_points, 2), edge_gauss%w(edge_gauss%n_points))
    edge_gauss%w = gauss1d%w
    
    SELECT CASE(edge_id)
      CASE(1)  ! Edge ξ = -1
        DO i = 1, edge_gauss%n_points
          edge_gauss%xi(i,:) = [-1.0_wp, gauss1d%xi(i,1)]
        END DO
      CASE(2)  ! Edge ξ = +1
        DO i = 1, edge_gauss%n_points
          edge_gauss%xi(i,:) = [1.0_wp, gauss1d%xi(i,1)]
        END DO
      CASE(3)  ! Edge η = -1
        DO i = 1, edge_gauss%n_points
          edge_gauss%xi(i,:) = [gauss1d%xi(i,1), -1.0_wp]
        END DO
      CASE(4)  ! Edge η = +1
        DO i = 1, edge_gauss%n_points
          edge_gauss%xi(i,:) = [gauss1d%xi(i,1), 1.0_wp]
        END DO
      CASE DEFAULT
        WRITE(*,*) "Quadrilateral edge ID must be 1-4, got:", edge_id
        ERROR STOP "Invalid edge ID"
    END SELECT
    
    DEALLOCATE(gauss1d%xi, gauss1d%w)
  END SUBROUTINE GetQuadEdgeGauss

END MODULE PH_Elem_GaussInt